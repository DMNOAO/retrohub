#define NOMINMAX
#if defined(_WIN32)
#include <windows.h>
#else
#include <dlfcn.h>
#endif

#include <stdint.h>
#include <stddef.h>

#include <algorithm>
#include <array>
#include <atomic>
#include <fstream>
#include <mutex>
#include <cstdio>
#include <cstring>
#include <deque>
#include <exception>
#include <string>
#include <unordered_map>
#include <vector>

// ============================================================
// Tipos básicos de Libretro
// ============================================================

typedef void (*retro_init_t)(void);
typedef void (*retro_deinit_t)(void);
typedef unsigned (*retro_api_version_t)(void);
typedef void (*retro_get_system_info_t)(void*);
typedef bool (*retro_load_game_t)(const void*);
typedef void (*retro_unload_game_t)(void);
typedef void (*retro_run_t)(void);
typedef void (*retro_get_system_av_info_t)(void*);
typedef size_t (*retro_serialize_size_t)(void);
typedef bool (*retro_serialize_t)(void*, size_t);
typedef bool (*retro_unserialize_t)(const void*, size_t);
typedef void* (*retro_get_memory_data_t)(unsigned);
typedef size_t (*retro_get_memory_size_t)(unsigned);

typedef void (*retro_set_environment_t)(
    bool (*)(unsigned, void*)
);

typedef void (*retro_set_video_refresh_t)(
    void (*)(const void*, unsigned, unsigned, size_t)
);

typedef void (*retro_set_audio_sample_t)(
    void (*)(int16_t, int16_t)
);

typedef void (*retro_set_audio_sample_batch_t)(
    size_t (*)(const int16_t*, size_t)
);

typedef void (*retro_set_input_poll_t)(
    void (*)(void)
);

typedef void (*retro_set_input_state_t)(
    int16_t (*)(unsigned, unsigned, unsigned, unsigned)
);

// Cable Link (rh_link_*) — símbolos OPCIONALES. Solo existen en
// cores compilados desde el fork RetroHub de SameBoy (ver
// native/sameboy_fork/RH_LINK_PATCH.md). En cualquier otro core
// (mGBA, un SameBoy sin forkear) simplemente no se encuentran al
// hacer dlsym, y todo lo de abajo se degrada a "no soportado" sin
// fallar.
// ============================================================

typedef bool (*rh_link_enable_t)(void);
typedef void (*rh_link_disable_t)(void);
typedef bool (*rh_link_connected_t)(void);
typedef bool (*rh_link_send_t)(const uint8_t*, size_t);
typedef int (*rh_link_receive_t)(uint8_t*, size_t);


// ============================================================
// Estructuras Libretro
// ============================================================

struct retro_game_info {
    const char* path;
    const void* data;
    size_t size;
    const char* meta;
};

struct retro_system_info {
    const char* library_name;
    const char* library_version;
    const char* valid_extensions;
    bool need_fullpath;
    bool block_extract;
};

struct retro_game_geometry {
    unsigned base_width, base_height, max_width, max_height;
    float aspect_ratio;
};

struct retro_system_timing {
    double fps, sample_rate;
};

struct retro_system_av_info {
    retro_game_geometry geometry;
    retro_system_timing timing;
};

struct retro_variable {
    const char* key;
    const char* value;
};

// Descriptores publicados por RETRO_ENVIRONMENT_SET_MEMORY_MAPS.
// mGBA usa este mecanismo para exponer EWRAM (0x02000000) e IWRAM
// (0x03000000), en vez de RETRO_MEMORY_SYSTEM_RAM.
struct retro_memory_descriptor {
    uint64_t flags;
    void* ptr;
    size_t offset;
    size_t start;
    size_t select;
    size_t disconnect;
    size_t len;
    const char* addrspace;
};

struct retro_memory_map {
    const retro_memory_descriptor* descriptors;
    unsigned num_descriptors;
};

// ============================================================
// Constantes Libretro
// ============================================================

#define RETRO_ENVIRONMENT_GET_CAN_DUPE 3
#define RETRO_ENVIRONMENT_GET_SYSTEM_DIRECTORY 9
#define RETRO_ENVIRONMENT_SET_PIXEL_FORMAT 10
#define RETRO_ENVIRONMENT_GET_VARIABLE 15
#define RETRO_ENVIRONMENT_SET_VARIABLES 16
#define RETRO_ENVIRONMENT_GET_VARIABLE_UPDATE 17
#define RETRO_ENVIRONMENT_GET_SAVE_DIRECTORY 31
#define RETRO_ENVIRONMENT_SET_GEOMETRY 37
#define RETRO_ENVIRONMENT_GET_CORE_OPTIONS_VERSION 52
#define RETRO_ENVIRONMENT_EXPERIMENTAL 0x10000
#define RETRO_ENVIRONMENT_SET_MEMORY_MAPS \
    (36 | RETRO_ENVIRONMENT_EXPERIMENTAL)

#define RETRO_PIXEL_FORMAT_0RGB1555 0
#define RETRO_PIXEL_FORMAT_XRGB8888 1
#define RETRO_PIXEL_FORMAT_RGB565 2

#define RETRO_HW_FRAME_BUFFER_VALID ((void*)-1)

#define RETRO_DEVICE_JOYPAD 1

#define RETRO_DEVICE_ID_JOYPAD_B 0
#define RETRO_DEVICE_ID_JOYPAD_Y 1
#define RETRO_DEVICE_ID_JOYPAD_SELECT 2
#define RETRO_DEVICE_ID_JOYPAD_START 3
#define RETRO_DEVICE_ID_JOYPAD_UP 4
#define RETRO_DEVICE_ID_JOYPAD_DOWN 5
#define RETRO_DEVICE_ID_JOYPAD_LEFT 6
#define RETRO_DEVICE_ID_JOYPAD_RIGHT 7
#define RETRO_DEVICE_ID_JOYPAD_A 8
#define RETRO_DEVICE_ID_JOYPAD_X 9
#define RETRO_DEVICE_ID_JOYPAD_L 10
#define RETRO_DEVICE_ID_JOYPAD_R 11
#define RETRO_DEVICE_ID_JOYPAD_L2 12
#define RETRO_DEVICE_ID_JOYPAD_R2 13
#define RETRO_DEVICE_ID_JOYPAD_L3 14
#define RETRO_DEVICE_ID_JOYPAD_R3 15

#define RETROHUB_BUTTON_COUNT 16

#define RETRO_MEMORY_SAVE_RAM 0
#define RETRO_MEMORY_RTC 1
#define RETRO_MEMORY_SYSTEM_RAM 2
#define RETRO_MEMORY_VIDEO_RAM 3

// ============================================================
// Estado del core
// ============================================================

#if defined(_WIN32)
using RhLibraryHandle = HMODULE;
#else
using RhLibraryHandle = void*;
#endif

#if defined(_WIN32)
#define RH_EXPORT extern "C" __declspec(dllexport)
#else
#define RH_EXPORT extern "C" __attribute__((visibility("default")))
#endif

static RhLibraryHandle core = nullptr;

static RhLibraryHandle rh_open_library(const char* path) {
#if defined(_WIN32)
    return LoadLibraryA(path);
#else
    return dlopen(path, RTLD_NOW | RTLD_LOCAL);
#endif
}

static void* rh_find_symbol(RhLibraryHandle library, const char* name) {
#if defined(_WIN32)
    return reinterpret_cast<void*>(GetProcAddress(library, name));
#else
    return dlsym(library, name);
#endif
}

static void rh_close_library(RhLibraryHandle library) {
    if (!library) return;
#if defined(_WIN32)
    FreeLibrary(library);
#else
    dlclose(library);
#endif
}


static retro_init_t retro_init_fn = nullptr;
static retro_deinit_t retro_deinit_fn = nullptr;
static retro_api_version_t retro_api_version_fn = nullptr;
static retro_get_system_info_t retro_get_system_info_fn = nullptr;
static retro_load_game_t retro_load_game_fn = nullptr;
static retro_unload_game_t retro_unload_game_fn = nullptr;
static retro_run_t retro_run_fn = nullptr;

static retro_serialize_size_t retro_serialize_size_fn = nullptr;
static retro_serialize_t retro_serialize_fn = nullptr;
static retro_unserialize_t retro_unserialize_fn = nullptr;
static retro_get_memory_data_t retro_get_memory_data_fn = nullptr;
static retro_get_memory_size_t retro_get_memory_size_fn = nullptr;

static retro_set_environment_t retro_set_environment_fn = nullptr;
static retro_set_video_refresh_t retro_set_video_refresh_fn = nullptr;
static retro_set_audio_sample_t retro_set_audio_sample_fn = nullptr;
static retro_set_audio_sample_batch_t retro_set_audio_sample_batch_fn =
    nullptr;
static retro_set_input_poll_t retro_set_input_poll_fn = nullptr;
static retro_set_input_state_t retro_set_input_state_fn = nullptr;
static retro_get_system_av_info_t retro_get_system_av_info_fn = nullptr;

// Opcionales: solo presentes si el core es el fork RetroHub de
// SameBoy con soporte Link Cable (ver typedefs más arriba).
static rh_link_enable_t rh_link_enable_fn = nullptr;
static rh_link_disable_t rh_link_disable_fn = nullptr;
static rh_link_connected_t rh_link_connected_fn = nullptr;
static rh_link_send_t rh_link_send_fn = nullptr;
static rh_link_receive_t rh_link_receive_fn = nullptr;

static bool core_initialized = false;
static bool game_loaded = false;

// Conserva los bytes de la ROM durante toda la sesión del juego.
static std::vector<uint8_t> rom_buffer;

// Copia propia de los descriptores. El arreglo original que entrega el core
// puede vivir sólo durante la llamada a environment_cb.
static std::vector<retro_memory_descriptor> memory_descriptors;
static std::mutex memory_map_mutex;

// ============================================================
// Configuración
// ============================================================

static std::string system_directory = ".";
static std::string save_directory = ".";
static std::unordered_map<std::string, std::string> core_variables;
static bool core_variables_updated = false;
static retro_game_geometry current_geometry{};

static unsigned current_pixel_format =
    RETRO_PIXEL_FORMAT_0RGB1555;

// ============================================================
// Frame buffer RGBA8888 para Flutter
// ============================================================

static std::vector<uint8_t> frame_buffer;

static unsigned frame_width = 0;
static unsigned frame_height = 0;
static bool frame_ready = false;

static std::mutex frame_mutex;

// PCM estéreo intercalado. Flutter drena esta cola en cada tick.
static std::deque<int16_t> audio_buffer;
static std::mutex audio_mutex;
static int audio_sample_rate = 48000;
static constexpr size_t MAX_AUDIO_SAMPLES = 48000 * 2 * 2;

// ============================================================
// Estado de entrada del jugador 1
// ============================================================

// Cada posición utiliza los IDs oficiales de RETRO_DEVICE_ID_JOYPAD_*.
// atomic permite que Flutter actualice el input mientras el core ejecuta frames.
static std::array<std::atomic<int16_t>, RETROHUB_BUTTON_COUNT>
    joypad_state{};

// ============================================================
// Utilidades de color
// ============================================================

static uint8_t expand_5_to_8(uint8_t value) {
    return static_cast<uint8_t>(
        (value << 3) | (value >> 2)
    );
}

static uint8_t expand_6_to_8(uint8_t value) {
    return static_cast<uint8_t>(
        (value << 2) | (value >> 4)
    );
}

// ============================================================
// Callback de entorno
// ============================================================

static bool environment_cb(
    unsigned command,
    void* data
) {
    switch (command) {
        case RETRO_ENVIRONMENT_SET_MEMORY_MAPS: {
            if (!data) {
                return false;
            }

            const auto* memory_map =
                static_cast<const retro_memory_map*>(data);

            if (!memory_map->descriptors || memory_map->num_descriptors == 0) {
                return false;
            }

            std::lock_guard<std::mutex> lock(memory_map_mutex);
            memory_descriptors.assign(
                memory_map->descriptors,
                memory_map->descriptors + memory_map->num_descriptors
            );
            return true;
        }

        case RETRO_ENVIRONMENT_SET_PIXEL_FORMAT: {
            if (!data) {
                return false;
            }

            const unsigned requested_format =
                *static_cast<const unsigned*>(data);

            switch (requested_format) {
                case RETRO_PIXEL_FORMAT_0RGB1555:
                case RETRO_PIXEL_FORMAT_XRGB8888:
                case RETRO_PIXEL_FORMAT_RGB565:
                    current_pixel_format = requested_format;
                    return true;

                default:
                    return false;
            }
        }

        case RETRO_ENVIRONMENT_GET_CORE_OPTIONS_VERSION:
            if (!data) {
                return false;
            }

            // RetroHub implementa por ahora la API clásica (V0). Es suficiente
            // para que los cores publiquen y consulten sus valores por defecto.
            *static_cast<unsigned*>(data) = 0;
            return true;

        case RETRO_ENVIRONMENT_SET_VARIABLES: {
            if (!data) {
                return false;
            }

            core_variables.clear();
            const auto* variable = static_cast<const retro_variable*>(data);

            while (variable->key != nullptr) {
                std::string definition = variable->value != nullptr
                    ? variable->value
                    : "";
                const size_t separator = definition.find(';');
                std::string choices = separator == std::string::npos
                    ? definition
                    : definition.substr(separator + 1);
                const size_t first_non_space = choices.find_first_not_of(" \t");
                if (first_non_space != std::string::npos) {
                    choices.erase(0, first_non_space);
                }
                const size_t next_choice = choices.find('|');
                core_variables[variable->key] = choices.substr(0, next_choice);
                ++variable;
            }

            core_variables_updated = false;
            return true;
        }

        case RETRO_ENVIRONMENT_GET_VARIABLE: {
            if (!data) {
                return false;
            }

            auto* variable = static_cast<retro_variable*>(data);
            if (!variable->key) {
                variable->value = nullptr;
                return false;
            }

            const auto found = core_variables.find(variable->key);
            if (found == core_variables.end()) {
                variable->value = nullptr;
                return false;
            }

            variable->value = found->second.c_str();
            return true;
        }

        case RETRO_ENVIRONMENT_GET_VARIABLE_UPDATE:
            if (!data) {
                return false;
            }

            *static_cast<bool*>(data) = core_variables_updated;
            core_variables_updated = false;
            return true;

        case RETRO_ENVIRONMENT_SET_GEOMETRY:
            if (!data) {
                return false;
            }

            current_geometry = *static_cast<const retro_game_geometry*>(data);
            return true;

        case RETRO_ENVIRONMENT_GET_SYSTEM_DIRECTORY:
            if (!data) {
                return false;
            }

            *static_cast<const char**>(data) =
                system_directory.c_str();

            return true;

        case RETRO_ENVIRONMENT_GET_SAVE_DIRECTORY:
            if (!data) {
                return false;
            }

            *static_cast<const char**>(data) =
                save_directory.c_str();

            return true;

        case RETRO_ENVIRONMENT_GET_CAN_DUPE:
            if (!data) {
                return false;
            }

            *static_cast<bool*>(data) = true;

            return true;

        default:
            return false;
    }
}

// ============================================================
// Conversión del frame entregado por Libretro a RGBA8888
// ============================================================

static void video_refresh_cb(
    const void* data,
    unsigned width,
    unsigned height,
    size_t pitch
) {
    if (!data || width == 0 || height == 0) {
        return;
    }

    if (data == RETRO_HW_FRAME_BUFFER_VALID) {
        return;
    }

    const size_t required_size =
        static_cast<size_t>(width) *
        static_cast<size_t>(height) *
        4;

    std::lock_guard<std::mutex> lock(frame_mutex);

    frame_buffer.resize(required_size);

    for (unsigned y = 0; y < height; y++) {
        const uint8_t* source_row =
            static_cast<const uint8_t*>(data) +
            (static_cast<size_t>(y) * pitch);

        for (unsigned x = 0; x < width; x++) {
            const size_t destination_index =
                (
                    static_cast<size_t>(y) *
                    static_cast<size_t>(width) +
                    static_cast<size_t>(x)
                ) * 4;

            uint8_t red = 0;
            uint8_t green = 0;
            uint8_t blue = 0;

            switch (current_pixel_format) {
                case RETRO_PIXEL_FORMAT_0RGB1555: {
                    const uint16_t pixel =
                        reinterpret_cast<
                            const uint16_t*
                        >(source_row)[x];

                    red = expand_5_to_8(
                        static_cast<uint8_t>(
                            (pixel >> 10) & 0x1F
                        )
                    );

                    green = expand_5_to_8(
                        static_cast<uint8_t>(
                            (pixel >> 5) & 0x1F
                        )
                    );

                    blue = expand_5_to_8(
                        static_cast<uint8_t>(
                            pixel & 0x1F
                        )
                    );

                    break;
                }

                case RETRO_PIXEL_FORMAT_RGB565: {
                    const uint16_t pixel =
                        reinterpret_cast<
                            const uint16_t*
                        >(source_row)[x];

                    red = expand_5_to_8(
                        static_cast<uint8_t>(
                            (pixel >> 11) & 0x1F
                        )
                    );

                    green = expand_6_to_8(
                        static_cast<uint8_t>(
                            (pixel >> 5) & 0x3F
                        )
                    );

                    blue = expand_5_to_8(
                        static_cast<uint8_t>(
                            pixel & 0x1F
                        )
                    );

                    break;
                }

                case RETRO_PIXEL_FORMAT_XRGB8888: {
                    const uint32_t pixel =
                        reinterpret_cast<
                            const uint32_t*
                        >(source_row)[x];

                    red = static_cast<uint8_t>(
                        (pixel >> 16) & 0xFF
                    );

                    green = static_cast<uint8_t>(
                        (pixel >> 8) & 0xFF
                    );

                    blue = static_cast<uint8_t>(
                        pixel & 0xFF
                    );

                    break;
                }

                default:
                    return;
            }

            frame_buffer[destination_index + 0] = red;
            frame_buffer[destination_index + 1] = green;
            frame_buffer[destination_index + 2] = blue;
            frame_buffer[destination_index + 3] = 255;
        }
    }

    frame_width = width;
    frame_height = height;
    frame_ready = true;
}

// ============================================================
// Audio
// ============================================================

static void audio_sample_cb(
    int16_t left,
    int16_t right
) {
    std::lock_guard<std::mutex> lock(audio_mutex);
    if (audio_buffer.size() + 2 > MAX_AUDIO_SAMPLES) {
        audio_buffer.pop_front();
        audio_buffer.pop_front();
    }
    audio_buffer.push_back(left);
    audio_buffer.push_back(right);
}

static size_t audio_sample_batch_cb(
    const int16_t* data,
    size_t frames
) {
    if (!data || frames == 0) return 0;
    const size_t sample_count = frames * 2;
    std::lock_guard<std::mutex> lock(audio_mutex);
    while (audio_buffer.size() + sample_count > MAX_AUDIO_SAMPLES &&
           !audio_buffer.empty()) {
        audio_buffer.pop_front();
    }
    audio_buffer.insert(audio_buffer.end(), data, data + sample_count);

    return frames;
}

// ============================================================
// Entrada
// ============================================================

static void input_poll_cb(void) {
    // Flutter actualiza joypad_state mediante rh_set_button_state().
    // Libretro llama a este callback una vez por frame antes de consultar
    // individualmente cada botón con input_state_cb().
}

static int16_t input_state_cb(
    unsigned port,
    unsigned device,
    unsigned index,
    unsigned id
) {
    // Por ahora RetroHub expone un solo mando: jugador 1, puerto 0.
    if (
        port != 0 ||
        device != RETRO_DEVICE_JOYPAD ||
        index != 0 ||
        id >= RETROHUB_BUTTON_COUNT
    ) {
        return 0;
    }

    return joypad_state[id].load(
        std::memory_order_relaxed
    );
}

static void reset_input_state() {
    for (auto& button : joypad_state) {
        button.store(
            0,
            std::memory_order_relaxed
        );
    }
}

static void reset_audio_state() {
    std::lock_guard<std::mutex> lock(audio_mutex);
    audio_buffer.clear();
    audio_sample_rate = 48000;
}

// ============================================================
// Limpieza interna
// ============================================================

static void clear_function_pointers() {
    retro_init_fn = nullptr;
    retro_deinit_fn = nullptr;
    retro_api_version_fn = nullptr;
    retro_get_system_info_fn = nullptr;
    retro_load_game_fn = nullptr;
    retro_unload_game_fn = nullptr;
    retro_run_fn = nullptr;
    retro_get_system_av_info_fn = nullptr;

    retro_serialize_size_fn = nullptr;
    retro_serialize_fn = nullptr;
    retro_unserialize_fn = nullptr;
    retro_get_memory_data_fn = nullptr;
    retro_get_memory_size_fn = nullptr;

    retro_set_environment_fn = nullptr;
    retro_set_video_refresh_fn = nullptr;
    retro_set_audio_sample_fn = nullptr;
    retro_set_audio_sample_batch_fn = nullptr;
    retro_set_input_poll_fn = nullptr;
    retro_set_input_state_fn = nullptr;

    rh_link_enable_fn = nullptr;
    rh_link_disable_fn = nullptr;
    rh_link_connected_fn = nullptr;
    rh_link_send_fn = nullptr;
    rh_link_receive_fn = nullptr;
}

static void reset_frame_state() {
    std::lock_guard<std::mutex> lock(frame_mutex);

    frame_buffer.clear();
    frame_width = 0;
    frame_height = 0;
    frame_ready = false;
}

// ============================================================
// Funciones exportadas para Dart FFI
// ============================================================

RH_EXPORT
void rh_set_button_state(
    int button_id,
    int pressed
) {
    if (
        button_id < 0 ||
        button_id >= RETROHUB_BUTTON_COUNT
    ) {
        return;
    }

    joypad_state[static_cast<size_t>(button_id)].store(
        pressed != 0 ? 1 : 0,
        std::memory_order_relaxed
    );
}

RH_EXPORT
int rh_get_button_state(int button_id) {
    if (
        button_id < 0 ||
        button_id >= RETROHUB_BUTTON_COUNT
    ) {
        return 0;
    }

    return static_cast<int>(
        joypad_state[static_cast<size_t>(button_id)].load(
            std::memory_order_relaxed
        )
    );
}

RH_EXPORT
void rh_reset_input() {
    reset_input_state();
}

RH_EXPORT
void rh_set_save_directory(const char* path) {
    if (path != nullptr && path[0] != '\0') {
        save_directory = path;
    }
}

RH_EXPORT
void rh_set_system_directory(const char* path) {
    if (path != nullptr && path[0] != '\0') {
        system_directory = path;
    }
}

RH_EXPORT
int rh_load_core(const char* core_path) {
    if (!core_path || core_path[0] == '\0') {
        return 0;
    }

    if (core) {
        return 1;
    }

    core = rh_open_library(core_path);

    if (!core) {
        return 0;
    }

    retro_init_fn =
        reinterpret_cast<retro_init_t>(
            rh_find_symbol(
                core,
                "retro_init"
            )
        );

    retro_deinit_fn =
        reinterpret_cast<retro_deinit_t>(
            rh_find_symbol(
                core,
                "retro_deinit"
            )
        );

    retro_api_version_fn =
        reinterpret_cast<retro_api_version_t>(
            rh_find_symbol(
                core,
                "retro_api_version"
            )
        );

    retro_get_system_info_fn =
        reinterpret_cast<retro_get_system_info_t>(
            rh_find_symbol(
                core,
                "retro_get_system_info"
            )
        );

    retro_load_game_fn =
        reinterpret_cast<retro_load_game_t>(
            rh_find_symbol(
                core,
                "retro_load_game"
            )
        );

    retro_unload_game_fn =
        reinterpret_cast<retro_unload_game_t>(
            rh_find_symbol(
                core,
                "retro_unload_game"
            )
        );

    retro_run_fn =
        reinterpret_cast<retro_run_t>(
            rh_find_symbol(
                core,
                "retro_run"
            )
            );

    retro_get_system_av_info_fn =
        reinterpret_cast<retro_get_system_av_info_t>(
            rh_find_symbol(core, "retro_get_system_av_info")
        );

    retro_serialize_size_fn =
        reinterpret_cast<retro_serialize_size_t>(
            rh_find_symbol(
                core,
                "retro_serialize_size"
            )
        );

    retro_serialize_fn =
        reinterpret_cast<retro_serialize_t>(
            rh_find_symbol(
                core,
                "retro_serialize"
            )
        );

    retro_unserialize_fn =
        reinterpret_cast<retro_unserialize_t>(
            rh_find_symbol(
                core,
                "retro_unserialize"
            )
        );

    retro_get_memory_data_fn =
        reinterpret_cast<retro_get_memory_data_t>(
            rh_find_symbol(
                core,
                "retro_get_memory_data"
            )
        );

    retro_get_memory_size_fn =
        reinterpret_cast<retro_get_memory_size_t>(
            rh_find_symbol(
                core,
                "retro_get_memory_size"
            )
        );

    retro_set_environment_fn =
        reinterpret_cast<retro_set_environment_t>(
            rh_find_symbol(
                core,
                "retro_set_environment"
            )
        );

    retro_set_video_refresh_fn =
        reinterpret_cast<retro_set_video_refresh_t>(
            rh_find_symbol(
                core,
                "retro_set_video_refresh"
            )
        );

    retro_set_audio_sample_fn =
        reinterpret_cast<retro_set_audio_sample_t>(
            rh_find_symbol(
                core,
                "retro_set_audio_sample"
            )
        );

    retro_set_audio_sample_batch_fn =
        reinterpret_cast<
            retro_set_audio_sample_batch_t
        >(
            rh_find_symbol(
                core,
                "retro_set_audio_sample_batch"
            )
        );

    retro_set_input_poll_fn =
        reinterpret_cast<retro_set_input_poll_t>(
            rh_find_symbol(
                core,
                "retro_set_input_poll"
            )
        );

    retro_set_input_state_fn =
        reinterpret_cast<retro_set_input_state_t>(
            rh_find_symbol(
                core,
                "retro_set_input_state"
            )
        );

    // Opcionales: no todos los cores los exportan (solo el fork
    // RetroHub de SameBoy). Un dlsym que no encuentra el símbolo
    // devuelve nullptr sin fallar, así que no hace falta try/catch
    // como en el lado Dart.
    rh_link_enable_fn =
        reinterpret_cast<rh_link_enable_t>(
            rh_find_symbol(core, "rh_link_enable")
        );

    rh_link_disable_fn =
        reinterpret_cast<rh_link_disable_t>(
            rh_find_symbol(core, "rh_link_disable")
        );

    rh_link_connected_fn =
        reinterpret_cast<rh_link_connected_t>(
            rh_find_symbol(core, "rh_link_connected")
        );

    rh_link_send_fn =
        reinterpret_cast<rh_link_send_t>(
            rh_find_symbol(core, "rh_link_send")
        );

    rh_link_receive_fn =
        reinterpret_cast<rh_link_receive_t>(
            rh_find_symbol(core, "rh_link_receive")
        );

    const bool all_functions_loaded =
        retro_init_fn &&
        retro_deinit_fn &&
        retro_api_version_fn &&
        retro_get_system_info_fn &&
        retro_load_game_fn &&
        retro_unload_game_fn &&
        retro_run_fn &&
        retro_get_system_av_info_fn &&
        retro_serialize_size_fn &&
        retro_serialize_fn &&
        retro_unserialize_fn &&
        retro_get_memory_data_fn &&
        retro_get_memory_size_fn &&
        retro_set_environment_fn &&
        retro_set_video_refresh_fn &&
        retro_set_audio_sample_fn &&
        retro_set_audio_sample_batch_fn &&
        retro_set_input_poll_fn &&
        retro_set_input_state_fn;

    if (!all_functions_loaded) {
        clear_function_pointers();

        rh_close_library(core);
        core = nullptr;

        return 0;
    }

    retro_set_environment_fn(environment_cb);
    retro_set_video_refresh_fn(video_refresh_cb);
    retro_set_audio_sample_fn(audio_sample_cb);
    retro_set_audio_sample_batch_fn(
        audio_sample_batch_cb
    );
    retro_set_input_poll_fn(input_poll_cb);
    retro_set_input_state_fn(input_state_cb);

    retro_init_fn();

    core_initialized = true;

    return 1;
}

RH_EXPORT
int rh_api_version() {
    if (!retro_api_version_fn) {
        return -1;
    }

    return static_cast<int>(
        retro_api_version_fn()
    );
}

RH_EXPORT
const char* rh_core_name() {
    static retro_system_info info{};

    if (!retro_get_system_info_fn) {
        return "Core no cargado";
    }

    retro_get_system_info_fn(&info);

    if (!info.library_name) {
        return "Core sin nombre";
    }

    return info.library_name;
}

RH_EXPORT
const char* rh_core_version() {
    static retro_system_info info{};

    if (!retro_get_system_info_fn) {
        return "Sin version";
    }

    retro_get_system_info_fn(&info);

    if (!info.library_version) {
        return "Sin version";
    }

    return info.library_version;
}

RH_EXPORT
const char* rh_core_extensions() {
    static retro_system_info info{};

    if (!retro_get_system_info_fn) {
        return "";
    }

    retro_get_system_info_fn(&info);

    if (!info.valid_extensions) {
        return "";
    }

    return info.valid_extensions;
}

RH_EXPORT
int rh_load_game(const char* rom_path) {
    if (
        !core_initialized ||
        !retro_load_game_fn ||
        !rom_path ||
        rom_path[0] == '\0'
    ) {
        return 0;
    }

    if (game_loaded) {
        return 1;
    }

    reset_frame_state();
    reset_audio_state();
    reset_input_state();
    rom_buffer.clear();

    std::ifstream rom_file(
        rom_path,
        std::ios::binary | std::ios::ate
    );

    if (!rom_file.is_open()) {
        return 0;
    }

    const std::streamsize rom_size =
        rom_file.tellg();

    if (rom_size <= 0) {
        rom_file.close();
        return 0;
    }

    rom_file.seekg(
        0,
        std::ios::beg
    );

    rom_buffer.resize(
        static_cast<size_t>(rom_size)
    );

    if (
        !rom_file.read(
            reinterpret_cast<char*>(
                rom_buffer.data()
            ),
            rom_size
        )
    ) {
        rom_file.close();
        rom_buffer.clear();

        return 0;
    }

    rom_file.close();

    retro_game_info game{};

    game.path = rom_path;
    game.data = rom_buffer.data();
    game.size = rom_buffer.size();
    game.meta = nullptr;

    bool loaded = false;

    // Some third-party cores throw a C++ exception for an unsupported or
    // malformed ROM instead of returning false. Never allow that exception to
    // cross the FFI boundary and terminate the entire Android process.
    try {
        loaded = retro_load_game_fn(&game);
    } catch (const std::exception& error) {
        std::fprintf(stderr, "retro_load_game failed: %s\n", error.what());
        loaded = false;
    } catch (...) {
        std::fprintf(stderr, "retro_load_game failed with an unknown exception\n");
        loaded = false;
    }

    if (!loaded) {
        rom_buffer.clear();
        game_loaded = false;

        return 0;
    }

    game_loaded = true;

    retro_system_av_info av_info{};
    retro_get_system_av_info_fn(&av_info);
    if (av_info.timing.sample_rate >= 8000.0 &&
        av_info.timing.sample_rate <= 192000.0) {
        audio_sample_rate = static_cast<int>(av_info.timing.sample_rate + 0.5);
    }

    return 1;
}

RH_EXPORT
int rh_get_audio_sample_rate() {
    return audio_sample_rate;
}

RH_EXPORT
size_t rh_read_audio_samples(int16_t* destination, size_t max_samples) {
    if (!destination || max_samples == 0) return 0;
    std::lock_guard<std::mutex> lock(audio_mutex);
    const size_t count = std::min(max_samples, audio_buffer.size());
    for (size_t index = 0; index < count; index++) {
        destination[index] = audio_buffer.front();
        audio_buffer.pop_front();
    }
    return count;
}

RH_EXPORT
void rh_clear_audio() {
    std::lock_guard<std::mutex> lock(audio_mutex);
    audio_buffer.clear();
}

RH_EXPORT
int rh_run_once() {
    if (
        !core_initialized ||
        !game_loaded ||
        !retro_run_fn
    ) {
        return 0;
    }

    retro_run_fn();

    return 1;
}

RH_EXPORT
const uint8_t* rh_get_frame_buffer() {
    std::lock_guard<std::mutex> lock(frame_mutex);

    if (frame_buffer.empty()) {
        return nullptr;
    }

    return frame_buffer.data();
}

RH_EXPORT
int rh_get_frame_width() {
    std::lock_guard<std::mutex> lock(frame_mutex);

    return static_cast<int>(frame_width);
}

RH_EXPORT
int rh_get_frame_height() {
    std::lock_guard<std::mutex> lock(frame_mutex);

    return static_cast<int>(frame_height);
}

RH_EXPORT
int rh_is_frame_ready() {
    std::lock_guard<std::mutex> lock(frame_mutex);

    return frame_ready ? 1 : 0;
}

RH_EXPORT
void rh_mark_frame_consumed() {
    std::lock_guard<std::mutex> lock(frame_mutex);

    frame_ready = false;
}



RH_EXPORT
size_t rh_get_memory_region_size(unsigned memory_id) {
    if (
        !game_loaded ||
        !retro_get_memory_size_fn
    ) {
        return 0;
    }

    return retro_get_memory_size_fn(memory_id);
}

RH_EXPORT
uintptr_t rh_get_memory_region_pointer(unsigned memory_id) {
    if (
        !game_loaded ||
        !retro_get_memory_data_fn
    ) {
        return 0;
    }

    return reinterpret_cast<uintptr_t>(
        retro_get_memory_data_fn(memory_id)
    );
}

RH_EXPORT
int rh_is_memory_region_mapped(unsigned memory_id) {
    if (
        !game_loaded ||
        !retro_get_memory_data_fn ||
        !retro_get_memory_size_fn
    ) {
        return 0;
    }

    return retro_get_memory_data_fn(memory_id) != nullptr &&
            retro_get_memory_size_fn(memory_id) > 0
        ? 1
        : 0;
}

RH_EXPORT
int rh_read_memory_byte(
    unsigned memory_id,
    size_t offset
) {
    if (
        !game_loaded ||
        !retro_get_memory_data_fn ||
        !retro_get_memory_size_fn
    ) {
        return -1;
    }

    void* memory_data =
        retro_get_memory_data_fn(memory_id);

    const size_t memory_size =
        retro_get_memory_size_fn(memory_id);

    if (
        !memory_data ||
        memory_size == 0 ||
        offset >= memory_size
    ) {
        return -1;
    }

    const uint8_t* bytes =
        static_cast<const uint8_t*>(memory_data);

    return static_cast<int>(bytes[offset]);
}

RH_EXPORT
size_t rh_read_memory_block(
    unsigned memory_id,
    size_t offset,
    uint8_t* destination,
    size_t destination_size
) {
    if (
        !game_loaded ||
        !retro_get_memory_data_fn ||
        !retro_get_memory_size_fn ||
        !destination ||
        destination_size == 0
    ) {
        return 0;
    }

    void* memory_data =
        retro_get_memory_data_fn(memory_id);

    const size_t memory_size =
        retro_get_memory_size_fn(memory_id);

    if (
        !memory_data ||
        memory_size == 0 ||
        offset >= memory_size
    ) {
        return 0;
    }

    const size_t available = memory_size - offset;
    const size_t bytes_to_copy =
        (destination_size < available ? destination_size : available);

    const uint8_t* source =
        static_cast<const uint8_t*>(memory_data) + offset;

    std::copy(
        source,
        source + bytes_to_copy,
        destination
    );

    return bytes_to_copy;
}

static const retro_memory_descriptor* find_gba_memory_descriptor(
    uint64_t address,
    size_t* relative
) {
    // Ruta literal usada por descriptores simples.
    for (const auto& descriptor : memory_descriptors) {
        if (!descriptor.ptr || descriptor.len == 0) {
            continue;
        }
        if (address >= descriptor.start &&
            address - descriptor.start < descriptor.len) {
            *relative = static_cast<size_t>(address - descriptor.start);
            return &descriptor;
        }
    }

    // Algunos cores describen el bus mediante select/disconnect y no publican
    // 0x02000000/0x03000000 como start literal. mGBA identifica ambas RAM por
    // su tamaño físico, que es inequívoco dentro del mapa GBA.
    uint64_t region_base = 0;
    size_t region_size = 0;
    if (address >= 0x02000000ULL && address < 0x02040000ULL) {
        region_base = 0x02000000ULL;
        region_size = 0x40000;
    } else if (address >= 0x03000000ULL && address < 0x03008000ULL) {
        region_base = 0x03000000ULL;
        region_size = 0x8000;
    } else {
        return nullptr;
    }

    for (const auto& descriptor : memory_descriptors) {
        if (!descriptor.ptr || descriptor.len != region_size) {
            continue;
        }
        *relative = static_cast<size_t>(address - region_base);
        return &descriptor;
    }
    return nullptr;
}

RH_EXPORT
int rh_is_memory_address_mapped(uint64_t address) {
    if (!game_loaded) {
        return 0;
    }

    {
        std::lock_guard<std::mutex> lock(memory_map_mutex);
        size_t relative = 0;
        if (find_gba_memory_descriptor(address, &relative)) {
            return 1;
        }
    }

    // mGBA también publica IWRAM como RETRO_MEMORY_SYSTEM_RAM.
    if (address >= 0x03000000ULL && address < 0x03008000ULL &&
        retro_get_memory_data_fn && retro_get_memory_size_fn) {
        return retro_get_memory_data_fn(RETRO_MEMORY_SYSTEM_RAM) &&
            retro_get_memory_size_fn(RETRO_MEMORY_SYSTEM_RAM) >= 0x8000
            ? 1
            : 0;
    }
    return 0;
}

RH_EXPORT
size_t rh_read_memory_address(
    uint64_t address,
    uint8_t* destination,
    size_t destination_size
) {
    if (!game_loaded || !destination || destination_size == 0) {
        return 0;
    }

    size_t total = 0;
    while (total < destination_size) {
        const uint64_t current = address + total;
        size_t relative = 0;
        size_t copied = 0;

        {
            std::lock_guard<std::mutex> lock(memory_map_mutex);
            const retro_memory_descriptor* match =
                find_gba_memory_descriptor(current, &relative);
            if (match) {
                const size_t available = match->len - relative;
                const size_t remaining = destination_size - total;
                copied = remaining < available ? remaining : available;
                const auto* source =
                    static_cast<const uint8_t*>(match->ptr) +
                    match->offset + relative;
                std::memcpy(destination + total, source, copied);
            }
        }

        if (copied == 0 &&
            current >= 0x03000000ULL && current < 0x03008000ULL &&
            retro_get_memory_data_fn && retro_get_memory_size_fn) {
            void* system_ram =
                retro_get_memory_data_fn(RETRO_MEMORY_SYSTEM_RAM);
            const size_t system_ram_size =
                retro_get_memory_size_fn(RETRO_MEMORY_SYSTEM_RAM);
            relative = static_cast<size_t>(current - 0x03000000ULL);
            if (system_ram && relative < system_ram_size) {
                const size_t available = system_ram_size - relative;
                const size_t remaining = destination_size - total;
                copied = remaining < available ? remaining : available;
                std::memcpy(
                    destination + total,
                    static_cast<const uint8_t*>(system_ram) + relative,
                    copied
                );
            }
        }

        if (copied == 0) {
            break;
        }
        total += copied;
    }

    return total;
}

RH_EXPORT
int rh_save_sram(const char* file_path) {
    if (
        !game_loaded ||
        !retro_get_memory_data_fn ||
        !retro_get_memory_size_fn ||
        !file_path ||
        file_path[0] == '\0'
    ) {
        return 0;
    }

    void* memory_data =
        retro_get_memory_data_fn(
            RETRO_MEMORY_SAVE_RAM
        );

    const size_t memory_size =
        retro_get_memory_size_fn(
            RETRO_MEMORY_SAVE_RAM
        );

    if (
        !memory_data ||
        memory_size == 0
    ) {
        return 0;
    }

    std::ofstream output(
        file_path,
        std::ios::binary |
        std::ios::trunc
    );

    if (!output.is_open()) {
        return 0;
    }

    output.write(
        static_cast<const char*>(
            memory_data
        ),
        static_cast<std::streamsize>(
            memory_size
        )
    );

    const bool success = output.good();

    output.close();

    return success ? 1 : 0;
}

RH_EXPORT
int rh_load_sram(const char* file_path) {
    if (
        !game_loaded ||
        !retro_get_memory_data_fn ||
        !retro_get_memory_size_fn ||
        !file_path ||
        file_path[0] == '\0'
    ) {
        return 0;
    }

    void* memory_data =
        retro_get_memory_data_fn(
            RETRO_MEMORY_SAVE_RAM
        );

    const size_t memory_size =
        retro_get_memory_size_fn(
            RETRO_MEMORY_SAVE_RAM
        );

    if (
        !memory_data ||
        memory_size == 0
    ) {
        return 0;
    }

    std::ifstream input(
        file_path,
        std::ios::binary |
        std::ios::ate
    );

    if (!input.is_open()) {
        return 0;
    }

    const std::streamsize file_size =
        input.tellg();

    if (
        file_size <= 0 ||
        static_cast<size_t>(file_size) !=
            memory_size
    ) {
        input.close();

        return 0;
    }

    input.seekg(
        0,
        std::ios::beg
    );

    const bool success =
        static_cast<bool>(
            input.read(
                static_cast<char*>(
                    memory_data
                ),
                file_size
            )
        );

    input.close();

    return success ? 1 : 0;
}

// ============================================================
// RTC (RETRO_MEMORY_RTC) — sigue exactamente el mismo mecanismo
// que SAVE_RAM. Se guarda/restaura como archivo binario aparte
// (por convención, "<nombre>.rtc" junto al "<nombre>.srm").
//
// A diferencia de rh_save_sram/rh_load_sram, que consideran un
// fallo de memoria como error, aquí NO tener RTC (juegos sin
// MBC3, p.ej. Red/Blue/Yellow) es un caso normal y se reporta
// como éxito (1), no como error (0).
// ============================================================

RH_EXPORT
int rh_core_has_rtc() {
    if (
        !game_loaded ||
        !retro_get_memory_size_fn
    ) {
        return 0;
    }

    return retro_get_memory_size_fn(RETRO_MEMORY_RTC) > 0 ? 1 : 0;
}

RH_EXPORT
int rh_save_rtc(const char* file_path) {
    if (
        !game_loaded ||
        !retro_get_memory_data_fn ||
        !retro_get_memory_size_fn ||
        !file_path ||
        file_path[0] == '\0'
    ) {
        return 0;
    }

    void* memory_data =
        retro_get_memory_data_fn(
            RETRO_MEMORY_RTC
        );

    const size_t memory_size =
        retro_get_memory_size_fn(
            RETRO_MEMORY_RTC
        );

    if (
        !memory_data ||
        memory_size == 0
    ) {
        // El core no expone RTC para este juego (p.ej. Red/Blue/
        // Yellow). No es un error: simplemente no hay nada que
        // guardar.
        fprintf(
            stderr,
            "[RetroHub RTC] Core sin RTC, nada que guardar\n"
        );

        return 1;
    }

    std::ofstream output(
        file_path,
        std::ios::binary |
        std::ios::trunc
    );

    if (!output.is_open()) {
        fprintf(
            stderr,
            "[RetroHub RTC] No se pudo abrir para guardar: %s\n",
            file_path
        );

        return 0;
    }

    output.write(
        static_cast<const char*>(
            memory_data
        ),
        static_cast<std::streamsize>(
            memory_size
        )
    );

    const bool success = output.good();

    output.close();

    if (success) {
        fprintf(stderr, "[RetroHub RTC] RTC guardado (%zu bytes): %s\n",
                memory_size, file_path);
    } else {
        fprintf(stderr, "[RetroHub RTC] Error guardando RTC: %s\n",
                file_path);
    }

    return success ? 1 : 0;
}

RH_EXPORT
int rh_load_rtc(const char* file_path) {
    if (
        !game_loaded ||
        !retro_get_memory_data_fn ||
        !retro_get_memory_size_fn ||
        !file_path ||
        file_path[0] == '\0'
    ) {
        return 0;
    }

    void* memory_data =
        retro_get_memory_data_fn(
            RETRO_MEMORY_RTC
        );

    const size_t memory_size =
        retro_get_memory_size_fn(
            RETRO_MEMORY_RTC
        );

    if (
        !memory_data ||
        memory_size == 0
    ) {
        // Sin RTC en este core/juego: nada que cargar, no es error.
        fprintf(
            stderr,
            "[RetroHub RTC] Core sin RTC, nada que cargar\n"
        );

        return 1;
    }

    std::ifstream input(
        file_path,
        std::ios::binary |
        std::ios::ate
    );

    if (!input.is_open()) {
        // Primera vez que se guarda esta partida: aún no existe
        // el archivo .rtc. No es un error.
        fprintf(
            stderr,
            "[RetroHub RTC] Archivo RTC no encontrado (primer uso): %s\n",
            file_path
        );

        return 1;
    }

    const std::streamsize file_size =
        input.tellg();

    if (
        file_size <= 0 ||
        static_cast<size_t>(file_size) !=
            memory_size
    ) {
        input.close();

        fprintf(
            stderr,
            "[RetroHub RTC] Tamaño de archivo RTC inesperado: %s\n",
            file_path
        );

        return 0;
    }

    input.seekg(
        0,
        std::ios::beg
    );

    const bool success =
        static_cast<bool>(
            input.read(
                static_cast<char*>(
                    memory_data
                ),
                file_size
            )
        );

    input.close();

    if (success) {
        fprintf(stderr, "[RetroHub RTC] RTC cargado (%zu bytes): %s\n",
                memory_size, file_path);
    } else {
        fprintf(stderr, "[RetroHub RTC] Error cargando RTC: %s\n",
                file_path);
    }

    return success ? 1 : 0;
}

RH_EXPORT
int rh_save_state(const char* file_path) {
    if (
        !game_loaded ||
        !retro_serialize_size_fn ||
        !retro_serialize_fn ||
        !file_path ||
        file_path[0] == '\0'
    ) {
        return 0;
    }

    const size_t state_size =
        retro_serialize_size_fn();

    if (state_size == 0) {
        return 0;
    }

    std::vector<uint8_t> state_buffer(
        state_size
    );

    const bool serialized =
        retro_serialize_fn(
            state_buffer.data(),
            state_buffer.size()
        );

    if (!serialized) {
        return 0;
    }

    std::ofstream output(
        file_path,
        std::ios::binary |
        std::ios::trunc
    );

    if (!output.is_open()) {
        return 0;
    }

    output.write(
        reinterpret_cast<const char*>(
            state_buffer.data()
        ),
        static_cast<std::streamsize>(
            state_buffer.size()
        )
    );

    const bool success = output.good();

    output.close();

    return success ? 1 : 0;
}

RH_EXPORT
int rh_load_state(const char* file_path) {
    if (
        !game_loaded ||
        !retro_unserialize_fn ||
        !file_path ||
        file_path[0] == '\0'
    ) {
        return 0;
    }

    std::ifstream input(
        file_path,
        std::ios::binary |
        std::ios::ate
    );

    if (!input.is_open()) {
        return 0;
    }

    const std::streamsize file_size =
        input.tellg();

    if (file_size <= 0) {
        input.close();

        return 0;
    }

    input.seekg(
        0,
        std::ios::beg
    );

    std::vector<uint8_t> state_buffer(
        static_cast<size_t>(
            file_size
        )
    );

    const bool read_success =
        static_cast<bool>(
            input.read(
                reinterpret_cast<char*>(
                    state_buffer.data()
                ),
                file_size
            )
        );

    input.close();

    if (!read_success) {
        return 0;
    }

    const bool loaded =
        retro_unserialize_fn(
            state_buffer.data(),
            state_buffer.size()
        );

    if (loaded) {
        reset_input_state();
        reset_frame_state();
    }

    return loaded ? 1 : 0;
}

RH_EXPORT
void rh_unload_game() {
    if (
        game_loaded &&
        retro_unload_game_fn
    ) {
        retro_unload_game_fn();
    }

    game_loaded = false;

    rom_buffer.clear();

    {
        std::lock_guard<std::mutex> lock(memory_map_mutex);
        memory_descriptors.clear();
    }

    reset_input_state();
    reset_frame_state();
}

RH_EXPORT
void rh_unload() {
    if (
        game_loaded &&
        retro_unload_game_fn
    ) {
        retro_unload_game_fn();
    }

    game_loaded = false;

    rom_buffer.clear();

    {
        std::lock_guard<std::mutex> lock(memory_map_mutex);
        memory_descriptors.clear();
    }

    if (
        core_initialized &&
        retro_deinit_fn
    ) {
        retro_deinit_fn();
    }

    core_initialized = false;

    clear_function_pointers();

    if (core) {
        rh_close_library(core);
        core = nullptr;
    }

    current_pixel_format =
        RETRO_PIXEL_FORMAT_0RGB1555;

    reset_input_state();
    reset_frame_state();
}

// ============================================================
// Cable Link (rh_link_*) — puente tolerante hacia los símbolos
// opcionales rh_link_* del core (solo presentes en el fork
// RetroHub de SameBoy, ver native/sameboy_fork/RH_LINK_PATCH.md).
//
// Estas funciones SIEMPRE existen en libretro_bridge.so (las
// exportamos nosotros), así que el lado Dart puede enlazarlas sin
// try/catch. La tolerancia real está acá adentro: si el core
// cargado no es el fork con soporte Link (mGBA, un SameBoy sin
// forkear, etc.), los punteros rh_link_*_fn quedan en nullptr y
// estas funciones devuelven "no soportado" sin fallar.
// ============================================================

RH_EXPORT
int rh_link_supported() {
    return (
        rh_link_enable_fn &&
        rh_link_disable_fn &&
        rh_link_connected_fn &&
        rh_link_send_fn &&
        rh_link_receive_fn
    ) ? 1 : 0;
}

RH_EXPORT
int rh_link_enable() {
    if (
        !game_loaded ||
        !rh_link_enable_fn
    ) {
        return 0;
    }

    return rh_link_enable_fn() ? 1 : 0;
}

RH_EXPORT
void rh_link_disable() {
    if (!rh_link_disable_fn) {
        return;
    }

    rh_link_disable_fn();
}

RH_EXPORT
int rh_link_connected() {
    if (!rh_link_connected_fn) {
        return 0;
    }

    return rh_link_connected_fn() ? 1 : 0;
}

RH_EXPORT
int rh_link_send(const uint8_t* data, size_t length) {
    if (
        !rh_link_send_fn ||
        !data ||
        length == 0
    ) {
        return 0;
    }

    return rh_link_send_fn(data, length) ? 1 : 0;
}

RH_EXPORT
int rh_link_receive(uint8_t* buffer, size_t max_length) {
    if (
        !rh_link_receive_fn ||
        !buffer ||
        max_length == 0
    ) {
        return 0;
    }

    return rh_link_receive_fn(buffer, max_length);
}

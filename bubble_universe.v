import gg
import math

const init_width = 800
const init_height = 600
const n = 200
const tau = math.pi * 2
const r = tau / 235.0

struct App {
mut:
        gg         &gg.Context = unsafe { nil }
        t          f64
        img_idx    int
        raw_pixels []u32
        curr_w     int
        curr_h     int
}

fn main() {
        mut app := &App{
                t:          0.0
                img_idx:    -1
                raw_pixels: []u32{len: init_width * init_height}
                curr_w:     init_width
                curr_h:     init_height
        }

        app.gg = gg.new_context(
                width: init_width
                height: init_height
                window_title: 'Bubble Universe'
                frame_fn: frame
                init_fn: init
                user_data: app
        )

        app.gg.run()
}

fn init(mut app App) {
        app.img_idx = app.gg.new_streaming_image(app.curr_w, app.curr_h, 4, gg.StreamingImageConfig{
                pixel_format: .rgba8
                mag_filter: .linear // Changed to linear for smoother scaling on resize
        })
}

fn frame(mut app App) {
        app.gg.begin()

        win_size := app.gg.window_size()
        w := win_size.width
        h := win_size.height

        if w != app.curr_w || h != app.curr_h {
                app.curr_w = w
                app.curr_h = h
                app.raw_pixels = []u32{len: w * h}
                app.gg.remove_cached_image_by_idx(app.img_idx)
                app.img_idx = app.gg.new_streaming_image(w, h, 4, gg.StreamingImageConfig{
                        pixel_format: .rgba8
                        mag_filter: .linear
                })
        }

        sw := f64(w) / 2.0
        sh := f64(h) / 2.0

        // Dynamic Scaling: Calculates sizing dynamically based on the current window constraints
        // 90.0 scale / 600.0 original height = ~0.15 ratio
        min_dim := if w < h { f64(w) } else { f64(h) }
        dynamic_sz := min_dim * 0.15

        mut x := 0.0
        mut v := 0.0

        unsafe {
                C.memset(app.raw_pixels.data, 0, usize(w * h) * sizeof[u32]())
        }

        for i := 0; i <= n; i++ {
                for j := 0; j <= n; j++ {
                        fi := f64(i)

                        u := math.sin(fi + v) + math.sin(r * fi + x)
                        v = math.cos(fi + v) + math.cos(r * fi + x)
                        x = u + app.t

                        r_col := u32((fi / f64(n)) * 255)
                        g_col := u32((f64(j) / f64(n)) * 255)
                        b_col := u32(220)
                        a_col := u32(255)

                        rgba_color := (a_col << 24) | (b_col << 16) | (g_col << 8) | r_col

                        // Applied dynamic_sz here to grow/shrink coordinates with the window bounds
                        plot_x := int(u * dynamic_sz + sw)
                        plot_y := int(v * dynamic_sz + sh)

                        if plot_x >= 0 && plot_x < w && plot_y >= 0 && plot_y < h {
                                pixel_index := plot_y * w + plot_x
                                app.raw_pixels[pixel_index] = rgba_color
                        }
                }
        }

        app.gg.update_pixel_data(app.img_idx, unsafe { &u8(app.raw_pixels.data) })

        img := app.gg.get_cached_image_by_idx(app.img_idx)
        app.gg.draw_image(0, 0, w, h, img)

        app.t += 1.0 / f64(n)
        app.gg.end()
}

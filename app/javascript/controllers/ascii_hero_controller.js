import { Controller } from "@hotwired/stimulus"

// The animated hero background: a tiny software raymarcher that renders a 3D
// scene into a grid of monospace characters, one ray per character. The scene
// is a curved wireframe tunnel with rotating octahedra in the project type
// colours. The pointer steers the camera, bends the picture like a lens and
// lights up the characters around it; a click sends a shockwave through the grid.
//
// It is decoration only: without JavaScript the canvas stays empty, with
// "reduce motion" it draws a single still frame, and it pauses while the hero
// is off screen or the tab is hidden.

const RAMP = " .:-=+*#%@"
const GLITCH = "01<>/\\{}[]$#"
const GREYS = ["#454d54", "#6a747d", "#9aa4ad"]
const ACCENT = GREYS.length // bucket index of the accent colour

const R = 3.0 // tunnel radius
const SEG = 10 // wall segments around the tunnel
const SEGW = (6.2831853 * R) / SEG // width of one segment
const RING = 3 // distance between rings
const P = 13 // distance between octahedra
const S = 0.68 // octahedron size
const MAXT = 42 // far plane
const FOV = 0.78
const SPEED = 4.5 // units per second
const MAX_CELLS = 10000
const LN = (MAXT + 8) * 4 // samples in the per-frame centre line table

const centreX = (z) => 0.9 * Math.sin(z * 0.09) + 0.5 * Math.sin(z * 0.047 + 1.3)
const centreY = (z) => 0.7 * Math.cos(z * 0.075) + 0.35 * Math.sin(z * 0.031)

export default class extends Controller {
  static targets = ["canvas", "stats"]
  static values = { colors: Array }

  connect() {
    this.ctx = this.canvasTarget.getContext("2d")
    this.reduced = matchMedia("(prefers-reduced-motion: reduce)").matches
    this.finePointer = matchMedia("(pointer: fine)").matches

    const accent = getComputedStyle(this.element).getPropertyValue("--accent").trim() || "#D4F25A"
    const kinds = this.colorsValue.length ? this.colorsValue : [accent]
    this.colors = [...GREYS, accent, ...kinds]
    this.kindCount = kinds.length

    this.lutX = new Float32Array(LN)
    this.lutY = new Float32Array(LN)
    this.mineX = new Float32Array(8)
    this.mineY = new Float32Array(8)
    this.rowStr = new Array(this.colors.length).fill("")
    this.rowLast = new Array(this.colors.length).fill(-1)

    this.minFont = 14
    this.camZ = 0
    this.last = 0
    this.running = false
    this.visible = true
    this.cost = 0
    this.fps = 60
    this.slow = 0
    this.statsAt = 0

    // pointer state in hero-relative pixels, plus the smoothed camera
    this.mx = this.my = this.glowX = this.glowY = -9999
    this.nx = this.ny = this.mActive = this.mTarget = this.yaw = this.pitch = 0
    this.waves = []

    this.onPointerMove = this.pointerMove.bind(this)
    this.onPointerDown = this.pointerDown.bind(this)
    this.onPointerLeave = () => { this.mTarget = 0 }
    this.onVisibility = this.updateRunning.bind(this)
    this.tick = this.tick.bind(this)

    addEventListener("pointermove", this.onPointerMove, { passive: true })
    document.documentElement.addEventListener("pointerleave", this.onPointerLeave)
    this.element.addEventListener("pointerdown", this.onPointerDown, { passive: true })
    document.addEventListener("visibilitychange", this.onVisibility)

    this.resizeObserver = new ResizeObserver(() => this.resize())
    this.resizeObserver.observe(this.element)
    this.intersectionObserver = new IntersectionObserver((entries) => {
      this.visible = entries[0].isIntersecting
      this.updateRunning()
    })
    this.intersectionObserver.observe(this.element)

    // The character width depends on the web font, so measure again once it is there.
    document.fonts?.ready.then(() => { if (this.ctx) this.resize() })

    this.resize()
    this.updateRunning()
  }

  disconnect() {
    this.running = false
    cancelAnimationFrame(this.raf)
    removeEventListener("pointermove", this.onPointerMove)
    document.documentElement.removeEventListener("pointerleave", this.onPointerLeave)
    this.element.removeEventListener("pointerdown", this.onPointerDown)
    document.removeEventListener("visibilitychange", this.onVisibility)
    this.resizeObserver.disconnect()
    this.intersectionObserver.disconnect()
    this.ctx = null
  }

  pointerMove(event) {
    if (!this.finePointer) return
    const rect = this.element.getBoundingClientRect()
    this.mx = event.clientX - rect.left
    this.my = event.clientY - rect.top
    this.mTarget = this.my >= 0 && this.my <= rect.height ? 1 : 0
    this.nx = Math.max(-1, Math.min(1, (this.mx / rect.width) * 2 - 1))
    this.ny = Math.max(-1, Math.min(1, (this.my / rect.height) * 2 - 1))
  }

  pointerDown(event) {
    if (this.reduced) return
    const rect = this.element.getBoundingClientRect()
    this.waves.push({ x: event.clientX - rect.left, y: event.clientY - rect.top, t0: performance.now() })
    if (this.waves.length > 3) this.waves.shift()
  }

  updateRunning() {
    const want = !this.reduced && this.visible && !document.hidden
    if (want && !this.running) {
      this.running = true
      this.last = performance.now()
      this.raf = requestAnimationFrame(this.tick)
    } else if (!want) {
      this.running = false
    }
  }

  tick(now) {
    if (!this.running) return
    this.render(now, false)
    this.raf = requestAnimationFrame(this.tick)
  }

  resize() {
    const ctx = this.ctx
    const rect = this.element.getBoundingClientRect()
    this.W = Math.max(1, rect.width)
    this.H = Math.max(1, rect.height)
    const dpr = Math.min(window.devicePixelRatio || 1, 2)
    this.canvasTarget.width = Math.round(this.W * dpr)
    this.canvasTarget.height = Math.round(this.H * dpr)

    // Pick the smallest font that keeps the number of rays per frame in budget.
    const family = getComputedStyle(this.canvasTarget).fontFamily
    let fontPx = Math.max(this.minFont, this.W < 700 ? 12 : 14)
    for (;;) {
      ctx.font = `${fontPx}px ${family}`
      this.cw = ctx.measureText("M").width
      this.ch = Math.round(fontPx * 1.3)
      this.cols = Math.ceil(this.W / this.cw)
      this.rows = Math.ceil(this.H / this.ch)
      if (this.cols * this.rows <= MAX_CELLS || fontPx >= 24) break
      fontPx++
    }
    this.fontPx = fontPx
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
    ctx.font = `${fontPx}px ${family}`
    ctx.textBaseline = "top"

    if (!this.running) this.render(performance.now(), true)
  }

  render(now, single) {
    const { ctx, W, H, cw, ch, cols, rows, lutX, lutY, mineX, mineY, rowStr, rowLast, colors, kindCount, waves } = this
    const NB = colors.length
    const dt = single ? 0 : Math.min(0.05, (now - this.last) / 1000 || 0.016)
    this.last = now
    const time = this.reduced ? 12.3 : now / 1000
    const started = performance.now()
    this.camZ = this.reduced ? 31 : this.camZ + dt * SPEED

    // --- camera ---
    const k = 1 - Math.pow(0.002, dt || 0.016)
    this.mActive += (this.mTarget - this.mActive) * k
    const mActive = this.mActive
    const targetYaw = mActive * this.nx * 0.6 + (1 - mActive) * 0.22 * Math.sin(time * 0.31)
    const targetPitch = mActive * -this.ny * 0.4 + (1 - mActive) * 0.14 * Math.sin(time * 0.23)
    this.yaw += (targetYaw - this.yaw) * k * 0.6
    this.pitch += (targetPitch - this.pitch) * k * 0.6
    const yaw = this.yaw, pitch = this.pitch
    if (this.glowX < -9000) { this.glowX = this.mx; this.glowY = this.my }
    this.glowX += (this.mx - this.glowX) * Math.min(1, k * 2.5)
    this.glowY += (this.my - this.glowY) * Math.min(1, k * 2.5)
    const glowX = this.glowX, glowY = this.glowY

    const oz = this.camZ
    const ox = centreX(oz) + yaw * 0.5, oy = centreY(oz) + pitch * 0.5
    let fx = centreX(oz + 4) - centreX(oz), fy = centreY(oz + 4) - centreY(oz), fz = 4
    let l = Math.hypot(fx, fy, fz); fx /= l; fy /= l; fz /= l
    let rx = fz, ry = 0, rz = -fx; l = Math.hypot(rx, rz); rx /= l; rz /= l
    let ux = fy * rz - fz * ry, uy = fz * rx - fx * rz, uz = fx * ry - fy * rx
    fx += rx * yaw + ux * pitch; fy += ry * yaw + uy * pitch; fz += rz * yaw + uz * pitch
    l = Math.hypot(fx, fy, fz); fx /= l; fy /= l; fz /= l
    rx = fz; ry = 0; rz = -fx; l = Math.hypot(rx, rz); rx /= l; rz /= l
    ux = fy * rz - fz * ry; uy = fz * rx - fx * rz; uz = fx * ry - fy * rx
    const roll = 0.22 * Math.sin(time * 0.13) + yaw * 0.25
    const cr = Math.cos(roll), sr = Math.sin(roll)

    // --- per-frame tables: tunnel centre line and octahedron positions ---
    const lutZ0 = Math.floor(oz) - 4
    for (let i = 0; i < LN; i++) { const z = lutZ0 + i * 0.25; lutX[i] = centreX(z); lutY[i] = centreY(z) }
    const k0 = Math.round(oz / P) - 1
    for (let i = 0; i < 8; i++) {
      const kk = k0 + i, z = kk * P, a = kk * 2.4
      mineX[i] = centreX(z) + Math.cos(a) * 1.55; mineY[i] = centreY(z) + Math.sin(a) * 1.55
    }
    const aY = time * 0.7, aX = time * 0.45
    const cY = Math.cos(aY), sY = Math.sin(aY), cX = Math.cos(aX), sX = Math.sin(aX)
    const pulseZ = oz - 4 + ((time * 16) % 70)

    const pxToU = (2 * FOV) / H
    const cellU = cw * pxToU, cellV = ch * pxToU
    const wide = W >= 700
    const vpX = wide ? W * 0.7 : W * 0.5 // the vanishing point sits in the free area right of the headline
    const vpY = H * 0.46
    const glowR2 = 170 * 170
    const nowMs = performance.now()
    for (let i = waves.length - 1; i >= 0; i--) if (nowMs - waves[i].t0 > 1800) waves.splice(i, 1)
    const nW = waves.length

    ctx.clearRect(0, 0, W, H)

    for (let j = 0; j < rows; j++) {
      const py = (j + 0.5) * ch
      for (let b = 0; b < NB; b++) { rowStr[b] = ""; rowLast[b] = -1 }

      for (let i = 0; i < cols; i++) {
        const px = (i + 0.5) * cw
        let u = (px - vpX) * pxToU, v = (vpY - py) * pxToU

        // pointer: lens and light
        const mdx = px - glowX, mdy = py - glowY
        const glow = mActive * Math.exp(-(mdx * mdx + mdy * mdy) / glowR2)
        u -= mdx * pxToU * 0.38 * glow; v += mdy * pxToU * 0.38 * glow

        // click shockwaves
        let boost = 0
        for (let w = 0; w < nW; w++) {
          const wave = waves[w], age = (nowMs - wave.t0) / 1000
          const wx = px - wave.x, wy = py - wave.y, dist = Math.sqrt(wx * wx + wy * wy) + 0.001
          const dd = dist - age * 800
          if (dd > -90 && dd < 90) {
            const kk = Math.exp((-dd * dd) / 1400) * (1 - age / 1.8)
            boost += kk; u += (wx / dist) * kk * 0.14; v -= (wy / dist) * kk * 0.14
          }
        }

        const u2 = u * cr - v * sr, v2 = u * sr + v * cr
        let dx = fx + rx * u2 + ux * v2, dy = fy + ry * u2 + uy * v2, dz = fz + rz * u2 + uz * v2
        const dl = 1 / Math.sqrt(dx * dx + dy * dy + dz * dz); dx *= dl; dy *= dl; dz *= dl

        // --- raymarch: 1 = tunnel wall, 2 = octahedron ---
        let t = 0, hit = 0, ex = 0, ey = 0, z = 0, bx = 0, by = 0, bz = 0, mk = 0
        for (let s = 0; s < 56; s++) {
          const x = ox + dx * t, y = oy + dy * t; z = oz + dz * t
          const f = (z - lutZ0) * 4; let li = f | 0
          if (li < 0) li = 0; else if (li > LN - 2) li = LN - 2
          const fr = f - li
          ex = x - (lutX[li] + (lutX[li + 1] - lutX[li]) * fr)
          ey = y - (lutY[li] + (lutY[li + 1] - lutY[li]) * fr)
          const dT = R - Math.sqrt(ex * ex + ey * ey)
          let dM = 1e9
          mk = Math.round(z / P); const mi = mk - k0
          if (mi >= 0 && mi < 8) {
            const ax = x - mineX[mi], ay = y - mineY[mi], az = z - mk * P
            bx = ax * cY + az * sY; const tz = -ax * sY + az * cY
            by = ay * cX - tz * sX; bz = ay * sX + tz * cX
            dM = (Math.abs(bx) + Math.abs(by) + Math.abs(bz) - S) * 0.5774
          }
          const d = dT < dM ? dT : dM
          if (d < 0.012 + t * 0.0015) { hit = dM < dT ? 2 : 1; break }
          t += d * 0.9; if (t > MAXT) break
        }
        if (!hit) continue

        // --- shade ---
        let b, bucket = -1, isLine = false
        if (hit === 1) {
          const a = Math.atan2(ey, ex) * (SEG / 6.2831853) + SEG, fa = a - Math.floor(a)
          const zz = z / RING, fzz = zz - Math.floor(zz)
          // keep lines at least about half a character wide at any distance, so they stay continuous
          const w = Math.max(0.03, (t * cellU * 0.5) / SEGW), w2 = Math.max(0.03, (t * cellV * 0.8) / RING)
          isLine = fa < w || fa > 1 - w || fzz < w2 || fzz > 1 - w2
          const fog = Math.exp(-t * 0.045)
          const pd = z - pulseZ, pulse = Math.exp(-pd * pd * 0.7)
          b = ((isLine ? 1 : 0.2) + pulse * (isLine ? 0.9 : 0.45)) * fog
        } else {
          const nxr = bx < 0 ? -0.5774 : 0.5774, nyr = by < 0 ? -0.5774 : 0.5774, nzr = bz < 0 ? -0.5774 : 0.5774
          const lx = -(dx * cY + dz * sY), tz = -(-dx * sY + dz * cY)
          const ly = -dy * cX - tz * sX, lz = -dy * sX + tz * cX
          let diff = nxr * lx + nyr * ly + nzr * lz; if (diff < 0) diff = 0
          const edge = Math.min(Math.abs(bx), Math.abs(by), Math.abs(bz)) < 0.04 + t * 0.002
          b = edge ? 1 : 0.3 + 0.5 * diff + (by < 0 ? 0 : 0.15)
          b *= Math.exp(-t * 0.04)
          bucket = ACCENT + 1 + (((mk % kindCount) + kindCount) % kindCount)
        }

        // keep the headline readable: dim the left side on wide screens, everything on narrow ones
        let mask = 0.42
        if (wide) { let m = (px / W - 0.3) / 0.35; m = m < 0 ? 0 : m > 1 ? 1 : m; mask = 0.2 + 0.8 * m * m * (3 - 2 * m) }
        b = b * mask * (1 + 1.6 * glow) + boost * (isLine || hit === 2 ? 0.8 : 0.35)
        if (b > 1) b = 1
        let ci = (b * 10) | 0; if (ci > 9) ci = 9
        if (ci < 1) continue
        if (bucket < 0) bucket = (isLine && b > 0.58) || boost > 0.45 ? ACCENT : b > 0.4 ? 2 : b > 0.22 ? 1 : 0

        const chr = boost > 0.5 ? GLITCH[(i * 7 + j * 13 + (nowMs >> 6)) % GLITCH.length] : RAMP[ci]
        const gap = i - rowLast[bucket] - 1
        rowStr[bucket] += (gap > 0 ? " ".repeat(gap) : "") + chr
        rowLast[bucket] = i
      }

      // one fillText per colour and row instead of one per character
      const y = j * ch
      for (let b = 0; b < NB; b++) {
        if (rowLast[b] < 0) continue
        ctx.fillStyle = colors[b]
        ctx.fillText(rowStr[b], 0, y)
      }
    }

    if (single) return

    // --- stats and adaptive quality: use bigger characters when a frame costs too much ---
    this.cost += (performance.now() - started - this.cost) * 0.1
    if (dt > 0) this.fps += (1 / dt - this.fps) * 0.05
    this.slow = this.cost > 13 ? this.slow + 1 : 0
    if (this.slow > 40 && this.minFont < 22) { this.slow = 0; this.minFont = this.fontPx + 2; this.resize() }
    if (this.hasStatsTarget && now - this.statsAt > 500) {
      this.statsAt = now
      this.statsTarget.textContent = `${this.cols}×${this.rows} chars · ${(this.cols * this.rows).toLocaleString("en")} rays/frame · ${Math.round(this.fps)} fps`
    }
  }
}

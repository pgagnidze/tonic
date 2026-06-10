-- Synthesizes licks as raw s16le audio and asserts tonic's verdicts.
-- Usage: luajit spec/smoke.lua  (or TONIC_CMD="lua5.4 tonic" lua5.4 spec/smoke.lua)

local RATE = 44100
local NOTE_TO_PC = { A = 9, B = 11, C = 0, ["C#"] = 1, D = 2, ["D#"] = 3, E = 4, ["F#"] = 6, G = 7 }

local function note_frequency(name)
    local midi = 60 + NOTE_TO_PC[name]
    return 440.0 * 2 ^ ((midi - 69) / 12)
end

local function synthesize(notes)
    math.randomseed(12345)
    local samples = {}
    local duration = 0.5
    for _, name in ipairs(notes) do
        local frequency = note_frequency(name)
        local count = math.floor(duration * RATE)
        for i = 0, count - 1 do
            local t = i / RATE
            local envelope = math.min(1.0, t / 0.02, (duration - t) / 0.05)
            local value = 0.5 * math.sin(2 * math.pi * frequency * t)
                + 0.2 * math.sin(2 * math.pi * 2 * frequency * t)
                + 0.1 * math.sin(2 * math.pi * 3 * frequency * t)
            samples[#samples + 1] = value * envelope * 0.5 + (math.random() - 0.5) * 0.004
        end
    end
    return samples
end

local function write_s16le(path, samples)
    local bytes = {}
    for i = 1, #samples do
        local value = math.floor(samples[i] * 32767 + 0.5)
        value = math.max(-32768, math.min(32767, value))
        if value < 0 then
            value = value + 65536
        end
        bytes[i] = string.char(value % 256, math.floor(value / 256))
    end
    local handle = assert(io.open(path, "wb"))
    handle:write(table.concat(bytes))
    handle:close()
end

local function verdict_of(path)
    local tonic_cmd = os.getenv("TONIC_CMD") or "./tonic"
    local handle = assert(io.popen(tonic_cmd .. " decide --input " .. path))
    local output = handle:read("*a")
    handle:close()
    return output
end

local function expect(label, path, needle)
    local output = verdict_of(path)
    if output:find(needle, 1, true) then
        print(string.format("PASS %s -> %s", label, needle))
        return true
    end
    print(string.format("FAIL %s: expected %q in:\n%s", label, needle, output))
    return false
end

local minor_lick = { "A", "C", "D", "D#", "E", "G", "A", "D", "C", "A" }
local major_lick = { "A", "B", "C#", "E", "F#", "A", "C#", "B", "F#", "A" }
local silence = {}
for _ = 1, RATE * 3 do
    silence[#silence + 1] = 0.0
end

write_s16le("/tmp/tonic-smoke-minor.raw", synthesize(minor_lick))
write_s16le("/tmp/tonic-smoke-major.raw", synthesize(major_lick))
write_s16le("/tmp/tonic-smoke-silence.raw", silence)

local ok = true
ok = expect("minor lick", "/tmp/tonic-smoke-minor.raw", "VERDICT: NO") and ok
ok = expect("major lick", "/tmp/tonic-smoke-major.raw", "VERDICT: YES") and ok
ok = expect("silence", "/tmp/tonic-smoke-silence.raw", "VERDICT: UNCLEAR") and ok

os.exit(ok and 0 or 1)

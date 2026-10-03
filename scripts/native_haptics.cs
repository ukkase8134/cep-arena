// Windows XInput bridge for controllers whose motor output fails through SDL.
// Input stays in Godot. This process only accepts bounded motor commands on stdin.
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading;

internal static class CepHaptics
{
    [StructLayout(LayoutKind.Sequential)] private struct Vibration { public ushort Left; public ushort Right; }
    [DllImport("xinput1_4.dll")] private static extern uint XInputSetState(uint index, ref Vibration vibration);
    private static readonly object Gate = new object();
    private static readonly int[] Generation = new int[4];
    private static readonly Timer[] Timers = new Timer[4];
    private static readonly bool[] Used = new bool[4];
    private static bool Closing;

    private static void Set(int index, int left, int right, int duration)
    {
        lock (Gate)
        {
            if (Closing) return;
            Generation[index]++;
            Used[index] = true;
            int generation = Generation[index];
            if (Timers[index] != null) Timers[index].Dispose();
            var vibration = new Vibration { Left = (ushort)left, Right = (ushort)right };
            XInputSetState((uint)index, ref vibration);
            if (duration <= 0) return;
            Timers[index] = new Timer(delegate
            {
                lock (Gate)
                {
                    if (Closing || Generation[index] != generation) return;
                    var stop = new Vibration();
                    XInputSetState((uint)index, ref stop);
                }
            }, null, duration, Timeout.Infinite);
        }
    }

    private static void StopAll()
    {
        lock (Gate)
        {
            if (Closing) return;
            Closing = true;
            for (uint index = 0; index < 4; index++)
            {
                if (!Used[index]) continue;
                if (Timers[index] != null) Timers[index].Dispose();
                var stop = new Vibration();
                XInputSetState(index, ref stop);
            }
        }
    }

    [STAThread] private static void Main(string[] args)
    {
        int parent;
        if (args.Length != 1 || !int.TryParse(args[0], out parent)) return;
        using (var watcher = new Timer(delegate
        {
            try { if (!Process.GetProcessById(parent).HasExited) return; } catch { }
            StopAll(); Environment.Exit(0);
        }, null, 500, 500))
        {
            try
            {
                string line;
                while ((line = Console.ReadLine()) != null)
                {
                    if (line == "quit") break;
                    var parts = line.Split(' ');
                    int index, left, right, duration;
                    if (parts.Length != 4 || !int.TryParse(parts[0], out index) || !int.TryParse(parts[1], out left) || !int.TryParse(parts[2], out right) || !int.TryParse(parts[3], out duration)) continue;
                    if (index < 0 || index > 3 || left < 0 || left > 65535 || right < 0 || right > 65535 || duration < 0 || duration > 2000) continue;
                    Set(index, left, right, duration);
                }
            }
            finally { StopAll(); }
        }
    }
}

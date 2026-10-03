"""Diagnostic only: call the Windows XInput API directly, always stop motors on exit."""
import ctypes, pathlib, time
from ctypes import wintypes

class Gamepad(ctypes.Structure):
    _fields_=[('buttons',wintypes.WORD),('left_trigger',ctypes.c_ubyte),('right_trigger',ctypes.c_ubyte),('lx',ctypes.c_short),('ly',ctypes.c_short),('rx',ctypes.c_short),('ry',ctypes.c_short)]
class State(ctypes.Structure):
    _fields_=[('packet',wintypes.DWORD),('gamepad',Gamepad)]
class Vibration(ctypes.Structure):
    _fields_=[('left',wintypes.WORD),('right',wintypes.WORD)]
class Caps(ctypes.Structure):
    _fields_=[('type',ctypes.c_ubyte),('subtype',ctypes.c_ubyte),('flags',wintypes.WORD),('gamepad',Gamepad),('vibration',Vibration)]

api=ctypes.WinDLL('XInput1_4.dll')
api.XInputGetState.argtypes=[wintypes.DWORD,ctypes.POINTER(State)]
api.XInputGetState.restype=wintypes.DWORD
api.XInputSetState.argtypes=[wintypes.DWORD,ctypes.POINTER(Vibration)]
api.XInputSetState.restype=wintypes.DWORD
api.XInputGetCapabilities.argtypes=[wintypes.DWORD,wintypes.DWORD,ctypes.POINTER(Caps)]
api.XInputGetCapabilities.restype=wintypes.DWORD
connected=[]
for index in range(4):
    state=State()
    result=api.XInputGetState(index,ctypes.byref(state))
    print('XINPUT_STATE',index,'result',result,flush=True)
    if result==0:
        connected.append(index)
        caps=Caps()
        result=api.XInputGetCapabilities(index,0,ctypes.byref(caps))
        print('CAPS',index,'result',result,'flags',hex(caps.flags),'subtype',caps.subtype,'motor_caps',caps.vibration.left,caps.vibration.right,flush=True)
try:
    for index in connected:
        for left,right,label in [(45000,0,'LEFT'),(0,45000,'RIGHT'),(55000,55000,'BOTH')]:
            vibration=Vibration(left,right)
            result=api.XInputSetState(index,ctypes.byref(vibration))
            print('DIRECT_RUMBLE',label,'index',index,'result',result,flush=True)
            time.sleep(0.9)
            api.XInputSetState(index,ctypes.byref(Vibration(0,0)))
            time.sleep(0.3)
    previous={}
    end=time.monotonic()+12
    while time.monotonic()<end:
        for index in connected:
            state=State()
            if api.XInputGetState(index,ctypes.byref(state))!=0: continue
            signature=(state.gamepad.buttons,state.gamepad.lx//5000,state.gamepad.ly//5000)
            if signature!=previous.get(index):
                previous[index]=signature
                print('DIRECT_INPUT',index,'buttons',hex(state.gamepad.buttons),'left_stick',state.gamepad.lx,state.gamepad.ly,flush=True)
        time.sleep(0.03)
finally:
    for index in connected: api.XInputSetState(index,ctypes.byref(Vibration(0,0)))
print('XINPUT_TEST_COMPLETE',flush=True)

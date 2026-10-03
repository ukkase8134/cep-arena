"""Real Godot simulation, four independent ENet processes, and rendered screenshots."""
import pathlib, subprocess, sys, time
ROOT=pathlib.Path(__file__).resolve().parents[1]
GODOT=next(iter(list((ROOT/'tools'/'editor').glob('*console.exe'))+list((ROOT/'tools'/'editor').glob('*linux.x86_64'))))
QA=ROOT/'qa'; QA.mkdir(exist_ok=True)
BASE=[str(GODOT),'--headless','--path',str(ROOT/'game')]

def simulation():
    result=subprocess.run(BASE+['--script','tests/simulation_test.gd'],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=60)
    (QA/'simulation.log').write_text(result.stdout+result.stderr,encoding='utf-8')
    print(result.stdout+result.stderr)
    if result.returncode or 'FAIL:' in result.stderr or 'SCRIPT ERROR' in result.stderr: raise RuntimeError('Simulation checks failed')

def network():
    logs=[]; children=[]
    try:
        log=open(QA/'host.log','w',encoding='utf-8'); logs.append(log)
        children.append(subprocess.Popen(BASE+['--','--smoke-host','--port=29872'],stdout=log,stderr=log))
        time.sleep(1)
        for i in range(3):
            log=open(QA/f'client{i}.log','w',encoding='utf-8'); logs.append(log)
            children.append(subprocess.Popen(BASE+['--','--smoke-client','--port=29872','--exit-after=20'],stdout=log,stderr=log))
        for child in children: child.wait(timeout=40)
        for log in logs: log.flush()
        output=(QA/'host.log').read_text(encoding='utf-8')
        print(output)
        if 'NETWORK_SMOKE_PASS 6 GAMES' not in output: raise RuntimeError('Host failed')
        if output.count('REGISTERED ')<3: raise RuntimeError('Not all four devices connected')
        for i,child in enumerate(children):
            data=(QA/('host.log' if i==0 else f'client{i-1}.log')).read_text(encoding='utf-8')
            if child.returncode or 'SCRIPT ERROR' in data or 'ERROR:' in data: raise RuntimeError(f'Process {i} failed: {data[:2400]}')
        print('FOUR_PROCESS_NETWORK_PASS')
    finally:
        for child in children:
            if child.poll() is None: child.kill()
        for log in logs: log.close()

def captures():
    for game in [-1,0,1,2,3,4,5]:
        dest=QA/('menu.png' if game<0 else f'game{game}.png')
        cmd=[str(GODOT),'--path',str(ROOT/'game'),'--',f'--capture={dest.as_posix()}']
        if game>=0: cmd.append(f'--demo={game}')
        result=subprocess.run(cmd,capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=20)
        (QA/f'capture{game}.log').write_text(result.stdout+result.stderr,encoding='utf-8')
        if result.returncode or not dest.exists() or 'SCRIPT ERROR' in result.stderr or 'ERROR:' in result.stderr: raise RuntimeError(result.stdout+result.stderr)
        print('RENDER_PASS',dest.name)

if __name__=='__main__':
    simulation()
    network()
    if '--captures' in sys.argv: captures()

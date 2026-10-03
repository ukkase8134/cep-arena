"""Fetch official Godot binaries and only the required members of its template ZIP.
HTTP ranges keep the other platform templates off disk. No third-party binary mirrors.
"""
import concurrent.futures, io, os, pathlib, struct, time, urllib.request, zipfile, zlib

ROOT = pathlib.Path(__file__).resolve().parents[1]
VERSION = '4.7.2-stable'
BASE = f'https://github.com/godotengine/godot-builds/releases/download/{VERSION}/'

def open_url(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent':'CepArenaBuilder/1.0'}), timeout=120)

def range_get(url, start, end):
    for attempt in range(5):
        try:
            req = urllib.request.Request(url, headers={'Range':f'bytes={start}-{end}', 'User-Agent':'CepArenaBuilder/1.0'})
            with urllib.request.urlopen(req, timeout=120) as response:
                if response.status != 206:
                    raise RuntimeError('Server must support byte ranges')
                data = response.read()
            if len(data) != end-start+1: raise RuntimeError('Short range response')
            return data
        except Exception:
            if attempt == 4: raise
            time.sleep(2+attempt)

def resolve(name):
    with open_url(BASE+name) as response:
        return response.url, int(response.headers['Content-Length'])

def parallel_bytes(url, start, size):
    chunks = [(s, min(s+1024*1024-1, start+size-1)) for s in range(start,start+size,1024*1024)]
    with concurrent.futures.ThreadPoolExecutor(max_workers=12) as pool:
        return b''.join(pool.map(lambda r:range_get(url,*r),chunks))

def editor():
    name=f'Godot_v{VERSION}_win64.exe.zip'
    dest=ROOT/'tools'/'editor'
    dest.mkdir(parents=True,exist_ok=True)
    if list(dest.glob('*console.exe')): return
    url,size=resolve(name)
    print(f'Fetching editor: {size//1048576} MiB',flush=True)
    data=parallel_bytes(url,0,size)
    with zipfile.ZipFile(io.BytesIO(data)) as archive: archive.extractall(dest)
    print('EDITOR_READY',flush=True)

def templates():
    url,size=resolve(f'Godot_v{VERSION}_export_templates.tpz')
    tail=range_get(url,size-65536,size-1)
    eocd=tail.rfind(b'PK\x05\x06')
    _,_,_,_,entries,cd_size,cd_offset,_=struct.unpack_from('<4s4H2IH',tail,eocd)
    central=range_get(url,cd_offset,cd_offset+cd_size-1)
    targets={'android_release.apk','android_debug.apk','windows_release_x86_64.exe','windows_debug_x86_64.exe','version.txt'}
    dest=pathlib.Path(os.environ['APPDATA'])/'Godot'/'export_templates'/'4.7.2.stable'
    dest.mkdir(parents=True,exist_ok=True)
    members=[]; pos=0
    for _ in range(entries):
        values=struct.unpack_from('<4s6H3I5H2I',central,pos)
        method,crc,packed,plain=values[4],values[7],values[8],values[9]
        n,x,c=values[10:13]; offset=values[16]
        name=central[pos+46:pos+46+n].decode('utf-8')
        pos+=46+n+x+c
        if name.split('/')[-1] in targets: members.append((name,method,crc,packed,plain,offset))
    for name,method,crc,packed,plain,offset in members:
        out=dest/name.split('/')[-1]
        if out.exists() and out.stat().st_size==plain: continue
        header=range_get(url,offset,offset+29)
        n,x=struct.unpack_from('<HH',header,26)
        print(f'Fetching {out.name}: {packed//1048576} MiB',flush=True)
        data=parallel_bytes(url,offset+30+n+x,packed)
        content=zlib.decompress(data,-15) if method==8 else data
        if len(content)!=plain or zlib.crc32(content)!=crc: raise RuntimeError('ZIP integrity mismatch')
        out.write_bytes(content)
        print(f'TEMPLATE_READY {out.name}',flush=True)

if __name__=='__main__':
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        list(pool.map(lambda f:f(),[editor,templates]))

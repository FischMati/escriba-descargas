"""Prueba el transcriptor instalado con una grabación de dominio público."""
import array
import hashlib
import os
from pathlib import Path
import struct
import subprocess
import wave

def descargar(url, archivo, sha):
    subprocess.run(["curl.exe", "-fsSL", "--retry", "3", url, "-o", str(archivo)], check=True)
    with archivo.open("rb") as entrada:
        assert hashlib.file_digest(entrada, "sha256").hexdigest() == sha, archivo.name

def entero(valor):
    salida = bytearray()
    while valor >= 128:
        salida.append((valor & 127) | 128)
        valor >>= 7
    salida.append(valor)
    return salida

def texto(valor):
    datos = valor.encode()
    return entero(len(datos)) + datos

def trama(datos):
    return struct.pack("<I", len(datos)) + datos

temporal = Path(os.environ["RUNNER_TEMP"])
modelo = temporal / "ggml-tiny.bin"
voz = temporal / "jfk.wav"
descargar("https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin", modelo,
          "be07e048e1e599ad46341c8d2a135645097a538221678b7acdd1b1919c6e1b21")
descargar("https://raw.githubusercontent.com/ggml-org/whisper.cpp/master/samples/jfk.wav", voz,
          "59dfb9a4acb36fe2a2affc14bacbee2920ff435cb13cc314a08c13f66ba7860e")
with wave.open(str(voz), "rb") as wav:
    assert (wav.getframerate(), wav.getnchannels(), wav.getsampwidth()) == (16000, 1, 2)
    valores = array.array("h", wav.readframes(wav.getnframes()))
pcm = array.array("f", (v / 32768.0 for v in valores))
solicitudes = (trama(b"\x00" + texto(str(modelo)) + b"\x00") +
               trama(b"\x01\x01" + entero(len(pcm)) + pcm.tobytes() + b"\x00\x01" + texto("en") + b"\x00") +
               trama(b"\x02"))
worker = Path(os.environ["LOCALAPPDATA"]) / "Escriba" / "escriba-asr-worker.exe"
salida = subprocess.run([str(worker)], input=solicitudes, stdout=subprocess.PIPE, check=True, timeout=180).stdout
respuestas = []
while salida:
    largo, = struct.unpack("<I", salida[:4])
    assert 0 < largo <= len(salida) - 4
    respuestas.append(salida[4:4+largo])
    salida = salida[4+largo:]
assert len(respuestas) == 2 and respuestas[0][0] == 0 and respuestas[1][0] == 1
assert b"country" in respuestas[1].lower()
print("El transcriptor instalado reconoció la grabación de prueba en Windows.")

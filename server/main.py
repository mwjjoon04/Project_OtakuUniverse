import os
import uuid
import asyncio
import hashlib
import subprocess
from pathlib import Path

import edge_tts
import uvicorn

from fastapi import FastAPI, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel


# ============================================================
# FastAPI
# ============================================================

app = FastAPI(
    title="Otaku Universe - Applio RVC Bridge Engine"
)


# ============================================================
# Applio Configuration
# ============================================================

APPLIO_DIR = Path(
    r"C:\txtingordow\ApplioV3.6.3"
)

APPLIO_PYTHON = (
    APPLIO_DIR / "env" / "python.exe"
)


# ============================================================
# Applio Output Directory
# ============================================================

APPLIO_OUTPUT_DIR = Path(
    r"C:\txtingordow\ApplioV3.6.3\assets\audios"
)


# ============================================================
# Temporary Working Directory
#
# 每一次 Request 都使用独立文件
# 防止旧音频 / 新音频互相覆盖
# ============================================================

TEMP_DIR = (
    APPLIO_DIR / "temp_rvc_api"
)


TEMP_DIR.mkdir(
    parents=True,
    exist_ok=True
)


# ============================================================
# Model Mapping
# ============================================================

CHARACTER_MODEL_MAP = {

    "luffy": {

        "model":
            r"logs\Luffy\Luffy.pth",

        "index":
            r"logs\Luffy\added_IVF842_Flat_nprobe_1_Luffy_v2.index",

    },

    "tanjiro": {

        "model":
            r"logs\tanjiro\tanjiro.pth",

        "index":
            r"logs\tanjiro\added_tanjiro_v2.index",

    },

}


# ============================================================
# Request Model
# ============================================================

class VoiceRequest(BaseModel):

    text: str

    character: str

    pitch_shift: int = -6


# ============================================================
# Generate Unique ID
# ============================================================

def create_request_id() -> str:

    return uuid.uuid4().hex


# ============================================================
# Generate Cache Key
#
# Python Backend 也生成唯一 Cache Key
# 用于避免相同 Request 重复调用 Applio
# ============================================================

def create_cache_key(
    text: str,
    character: str,
    pitch: int,
) -> str:

    raw_key = (
        f"{character.lower()}|"
        f"{pitch}|"
        f"{text.strip()}"
    )

    return hashlib.sha256(
        raw_key.encode("utf-8")
    ).hexdigest()


# ============================================================
# Generate Base Japanese TTS
# ============================================================

async def generate_tts_base(
    text: str,
    character: str,
    output_path: Path,
):

    character_key = (
        character.lower()
    )


    # --------------------------------------------------------
    # Japanese TTS Voice
    # --------------------------------------------------------

    if character_key in [
        "tanjiro",
        "luffy",
    ]:

        voice = (
            "ja-JP-KeitaNeural"
        )

    else:

        voice = (
            "ja-JP-NanamiNeural"
        )


    print(
        f"🗣️ [Edge TTS]"
    )

    print(
        f"🎭 Character: "
        f"{character_key}"
    )

    print(
        f"🎙️ Voice: "
        f"{voice}"
    )

    print(
        f"📝 Text: "
        f"{text}"
    )


    communicate = (
        edge_tts.Communicate(
            text,
            voice,
        )
    )


    await communicate.save(
        str(output_path)
    )


    if not output_path.exists():

        raise RuntimeError(
            "Edge TTS 没有成功生成音频文件"
        )


    if output_path.stat().st_size <= 0:

        raise RuntimeError(
            "Edge TTS 生成的音频文件为空"
        )


    print(
        f"✅ [Edge TTS 成功]"
    )

    print(
        f"📁 {output_path}"
    )


# ============================================================
# Get Character Model
# ============================================================

def get_character_model(
    character: str,
):

    character_key = (
        character.lower()
    )


    if character_key not in CHARACTER_MODEL_MAP:

        raise ValueError(
            f"不支持的角色: "
            f"{character}"
        )


    return (
        CHARACTER_MODEL_MAP[
            character_key
        ]
    )


# ============================================================
# Convert Voice With Applio
# ============================================================

def convert_with_applio(
    input_mp3: Path,
    character: str,
    pitch: int,
    output_wav: Path,
):

    char_info = (
        get_character_model(
            character
        )
    )


    model_file = (
        char_info["model"]
    )


    index_file = (
        char_info["index"]
    )


    # --------------------------------------------------------
    # Convert Relative Paths
    # Applio core.py 在 APPLIO_DIR 运行
    # --------------------------------------------------------

    print(
        f"🎯 [Voice Model]"
    )

    print(
        model_file
    )


    print(
        f"🧬 [Index File]"
    )

    print(
        index_file
    )


    print(
        f"🎙️ [Input]"
    )

    print(
        str(input_mp3)
    )


    print(
        f"🎵 [Output]"
    )

    print(
        str(output_wav)
    )


    # --------------------------------------------------------
    # Applio CLI
    # --------------------------------------------------------

    cmd = [

        str(APPLIO_PYTHON),

        "core.py",

        "infer",

        "--input_path",
        str(input_mp3),

        "--output_path",
        str(output_wav),

        "--pth_path",
        model_file,

        "--index_path",
        index_file,

        "--pitch",
        str(pitch),

        "--index_rate",
        "0.75",

        "--f0_method",
        "rmvpe",

        "--protect",
        "0.33",

        "--volume_envelope",
        "0.33",

        "--clean_audio",
        "True",

        "--clean_strength",
        "0.5",

        "--export_format",
        "WAV",

    ]


    print(
        "⚙️ [Applio] 开始执行 CLI..."
    )


    # --------------------------------------------------------
    # Run Applio
    # --------------------------------------------------------

    result = subprocess.run(

        cmd,

        cwd=str(
            APPLIO_DIR
        ),

        capture_output=True,

        text=True,

        timeout=180,

        encoding="utf-8",

        errors="ignore",

    )


    # --------------------------------------------------------
    # Print Output
    # --------------------------------------------------------

    print(
        "========== Applio STDOUT =========="
    )

    print(
        result.stdout
    )


    print(
        "========== Applio STDERR =========="
    )

    print(
        result.stderr
    )


    # --------------------------------------------------------
    # Check CLI Result
    # --------------------------------------------------------

    if result.returncode != 0:

        raise RuntimeError(

            "Applio CLI 执行失败:\n"

            + result.stderr

        )


    # --------------------------------------------------------
    # Check Output File
    # --------------------------------------------------------

    if not output_wav.exists():

        raise RuntimeError(

            "Applio 执行成功，但没有找到输出 WAV:\n"

            + str(output_wav)

        )


    if output_wav.stat().st_size <= 0:

        raise RuntimeError(

            "Applio 输出 WAV 文件为空"

        )


    print(
        "🎉 [Applio 成功]"
    )

    print(
        f"📁 {output_wav}"
    )

    print(
        f"📦 Size: "
        f"{output_wav.stat().st_size} bytes"
    )


    return output_wav


# ============================================================
# Cleanup Temporary Files
# ============================================================

def cleanup_file(
    file_path: Path,
):

    try:

        if file_path.exists():

            file_path.unlink()

            print(
                f"🗑️ [Cleanup] "
                f"{file_path}"
            )

    except Exception as e:

        print(
            f"⚠️ [Cleanup Failed] "
            f"{file_path}"
        )

        print(
            str(e)
        )


# ============================================================
# Main Voice Clone API
# ============================================================

@app.post(
    "/api/voice-clone"
)
async def generate_cloned_voice(
    req: VoiceRequest,
):

    # ========================================================
    # Validate Text
    # ========================================================

    if not req.text.strip():

        raise HTTPException(

            status_code=400,

            detail=(
                "Text cannot be empty"
            )

        )


    # ========================================================
    # Normalize Character
    # ========================================================

    character_key = (
        req.character.lower().strip()
    )


    # ========================================================
    # Validate Character
    # ========================================================

    if character_key not in CHARACTER_MODEL_MAP:

        raise HTTPException(

            status_code=400,

            detail=(
                f"Unsupported character: "
                f"{req.character}"
            )

        )


    # ========================================================
    # Validate Pitch
    # ========================================================

    if req.pitch_shift < -24:

        raise HTTPException(

            status_code=400,

            detail=(
                "pitch_shift 最小值是 -24"
            )

        )


    if req.pitch_shift > 24:

        raise HTTPException(

            status_code=400,

            detail=(
                "pitch_shift 最大值是 24"
            )

        )


    # ========================================================
    # Unique Request ID
    # ========================================================

    request_id = (
        create_request_id()
    )


    # ========================================================
    # Unique File Paths
    #
    # 每个 Request 都不同
    #
    # 防止：
    #
    # Request A
    # temp_input.mp3
    #
    # Request B
    # temp_input.mp3
    #
    # 互相覆盖
    # ========================================================

    temp_input = (

        TEMP_DIR

        / f"{request_id}_input.mp3"

    )


    temp_output = (

        TEMP_DIR

        / f"{request_id}_output.wav"

    )


    # ========================================================
    # Log Request
    # ========================================================

    print()

    print(
        "=================================================="
    )

    print(
        "🎙️ [NEW VOICE REQUEST]"
    )

    print(
        f"🆔 Request ID: "
        f"{request_id}"
    )

    print(
        f"🎭 Character: "
        f"{character_key}"
    )

    print(
        f"📝 Text: "
        f"{req.text}"
    )

    print(
        f"🎚️ Pitch: "
        f"{req.pitch_shift}"
    )

    print(
        "=================================================="
    )


    try:

        # ====================================================
        # STEP 1
        # Edge TTS
        # ====================================================

        await generate_tts_base(

            req.text,

            character_key,

            temp_input,

        )


        # ====================================================
        # STEP 2
        # Applio RVC
        # ====================================================

        output_wav_path = (

            await asyncio.to_thread(

                convert_with_applio,

                temp_input,

                character_key,

                req.pitch_shift,

                temp_output,

            )

        )


        # ====================================================
        # STEP 3
        # Read WAV
        # ====================================================

        with open(

            output_wav_path,

            "rb",

        ) as f:

            audio_bytes = (
                f.read()
            )


        if not audio_bytes:

            raise RuntimeError(

                "最终生成的 WAV 音频为空"

            )


        # ====================================================
        # STEP 4
        # Cleanup Input
        # ====================================================

        cleanup_file(
            temp_input
        )


        # ====================================================
        # SUCCESS
        # ====================================================

        print()

        print(
            "🎉 [SUCCESS]"
        )

        print(
            f"🎭 Character: "
            f"{character_key}"
        )

        print(
            f"📝 Text: "
            f"{req.text}"
        )

        print(
            f"📦 Audio Size: "
            f"{len(audio_bytes)} bytes"
        )

        print(
            "🚀 Sending WAV to Flutter..."
        )


        return Response(

            content=audio_bytes,

            media_type="audio/wav",

            headers={

                "X-Request-ID":
                    request_id,

                "X-Character":
                    character_key,

            },

        )


    except subprocess.TimeoutExpired:

        print(
            "❌ [Applio Timeout]"
        )


        raise HTTPException(

            status_code=504,

            detail=(
                "Applio 处理超过 "
                "180 秒"
            )

        )


    except Exception as e:

        print()

        print(
            "❌ [VOICE CONVERSION ERROR]"
        )

        print(
            f"Error: {e}"
        )


        raise HTTPException(

            status_code=500,

            detail=str(e),

        )


    finally:

        # ====================================================
        # Always Cleanup
        # ====================================================

        cleanup_file(
            temp_input
        )

        cleanup_file(
            temp_output
        )


# ============================================================
# Start Server
# ============================================================

if __name__ == "__main__":

    print()

    print(
        "🚀 ============================================"
    )

    print(
        "🚀 Otaku Universe Applio RVC Server"
    )

    print(
        "🚀 Port: 8000"
    )

    print(
        "🚀 ============================================"
    )

    print()


    uvicorn.run(

        app,

        host="0.0.0.0",

        port=8000,

    )
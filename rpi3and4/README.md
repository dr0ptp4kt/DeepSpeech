# Compiling DeepSpeech with TensorFlow Lite bindings for Raspberry Pi 4 or Raspberry Pi 3

The docs.json file in this directory uses English Wikipedia content, which was licensed under the [Creative Commons Attribution-ShareAlike License] (https://en.wikipedia.org/wiki/Wikipedia:Text_of_Creative_Commons_Attribution-ShareAlike_3.0_Unported_License).

If you want to be able to create something like an [offline voice based Wikipedia](https://www.icloud.com/sharedalbum/#B0B5ON9t3uAsJR;12EB94FB-FA2D-401E-A7B5-895597BABEB9) that runs on an inexpensive Raspberry Pi device, this tutoriala may be what you're looking for.

The eventual target deployment device is a Raspberry Pi 4 or Raspberry Pi 3. For good performance and accuracy, use a Raspberry Pi 4 with 2 GB of RAM or more.

If you have a Raspberry Pi 3, which has only 1 GB or RAM, when you get to the end of this tutorial, if you want to get reasonable speed, you'll want to either produce and use a smaller lm.binary or execute the commands without the language model and trie (i.e., remove "--lm deepspeech-0.5.1-models/lm.binary.copy --trie deepspeech-0.5.1-models/trie.copy" from command invocation). You can fiddle with this to get the appropriate accuracy and speed of execution for your context.

On my Raspberry Pi with 4GB of RAM this runs fast even when using the --lm and --trie flags. Without the --lm and --trie flags, on my Raspberry Pi 3 it takes about 21.9s to run using the stock .tflite model, which is much better than the 95s it takes with the --lm and --trie flags in use...but it would run even faster if I could fit the language model in RAM from what I can tell...a different project for a different day.

Anyway, here it goes.

0. On your computer configure Docker to use 10 GB of RAM if you can. I know that works on my Mac. It may be possible to get by with less like 8 GB or 4 GB or RAM, but I know 10 GB works for sure. The default 2GB of RAM will result in errors during build, so don't use the default. Now build the docker container from **this** directory where **this** README.md resides and run it!

```bash
docker build --tag deepspeech:rpi3and4 --file Dockerfile.rpi3and4 .
docker run -it deepspeech:rpi3and4
```


1. From /tensorflow in the Docker container configure and answer the prompts as follows:
```bash
./configure
Extracting Bazel installation...
WARNING: --batch mode is deprecated. Please instead explicitly shut down your Bazel server using the command "bazel shutdown".
You have bazel 0.19.2 installed.
Do you wish to build TensorFlow with XLA JIT support? [Y/n]: n
No XLA JIT support will be enabled for TensorFlow.

Do you wish to build TensorFlow with OpenCL SYCL support? [y/N]: N
No OpenCL SYCL support will be enabled for TensorFlow.

Do you wish to build TensorFlow with ROCm support? [y/N]: N
No ROCm support will be enabled for TensorFlow.

Do you wish to build TensorFlow with CUDA support? [y/N]: N
No CUDA support will be enabled for TensorFlow.

Do you wish to download a fresh release of clang? (Experimental) [y/N]: N
Clang will not be downloaded.

Do you wish to build TensorFlow with MPI support? [y/N]: N
No MPI support will be enabled for TensorFlow.

Please specify optimization flags to use during compilation when bazel option "--config=opt" is specified [Default is -march=native -Wno-sign-compare]: 


Would you like to interactively configure ./WORKSPACE for Android builds? [y/N]: N
Not configuring the WORKSPACE for Android builds.
```


2. In the running Docker container, adapt the following files with the following diff. Do notice that /tensorflow has a sub-folder called tensorflow - don't get confused! This is just a workaround - a proper fix would be to adjust things with better logic flow in the make, Bazel and C++ files specifically for the architecture. I had been having some problems debugging the logic flow between all of the building so ended up taking the more expedient route just to get this proof of concept working.

```bash
vi tensorflow/lite/kernels/internal/BUILD
vi tensorflow/lite/kernels/internal/optimized/tensor_utils_impl.h
vi tensorflow/lite/kernels/internal/tensor_utils.cc
vi native_client/definitions.mk
```

The diffs:

```bash
root:/tensorflow# git diff
diff --git a/tensorflow/lite/kernels/internal/BUILD b/tensorflow/lite/kernels/internal/BUILD
index 4be3226938..7e2f66cc58 100644
--- a/tensorflow/lite/kernels/internal/BUILD
+++ b/tensorflow/lite/kernels/internal/BUILD
@@ -535,7 +535,7 @@ cc_library(
             ":neon_tensor_utils",
         ],
         "//conditions:default": [
-            ":portable_tensor_utils",
+            ":neon_tensor_utils",
         ],
     }),
 )
diff --git a/tensorflow/lite/kernels/internal/optimized/tensor_utils_impl.h b/tensorflow/lite/kernels/internal/optimized/tensor_utils_impl.h
index 8f52ef131d..780ae1da6c 100644
--- a/tensorflow/lite/kernels/internal/optimized/tensor_utils_impl.h
+++ b/tensorflow/lite/kernels/internal/optimized/tensor_utils_impl.h
@@ -24,9 +24,9 @@ limitations under the License.
 #endif
 
 #ifndef USE_NEON
-#if defined(__ARM_NEON__) || defined(__ARM_NEON)
+//#if defined(__ARM_NEON__) || defined(__ARM_NEON)
 #define USE_NEON
-#endif  //  defined(__ARM_NEON__) || defined(__ARM_NEON)
+//#endif  //  defined(__ARM_NEON__) || defined(__ARM_NEON)
 #endif  //  USE_NEON
 
 namespace tflite {
diff --git a/tensorflow/lite/kernels/internal/tensor_utils.cc b/tensorflow/lite/kernels/internal/tensor_utils.cc
index 701e5a66aa..21f2723c3b 100644
--- a/tensorflow/lite/kernels/internal/tensor_utils.cc
+++ b/tensorflow/lite/kernels/internal/tensor_utils.cc
@@ -16,9 +16,9 @@ limitations under the License.
 #include "tensorflow/lite/kernels/internal/common.h"
 
 #ifndef USE_NEON
-#if defined(__ARM_NEON__) || defined(__ARM_NEON)
+//#if defined(__ARM_NEON__) || defined(__ARM_NEON)
 #define USE_NEON
-#endif  //  defined(__ARM_NEON__) || defined(__ARM_NEON)
+//#endif  //  defined(__ARM_NEON__) || defined(__ARM_NEON)
 #endif  //  USE_NEON
 
 #ifdef USE_NEON

root:/DeepSpeech/native_client# git diff
diff --git a/native_client/definitions.mk b/native_client/definitions.mk
index da404a6..68f9573 100644
--- a/native_client/definitions.mk
+++ b/native_client/definitions.mk
@@ -1,7 +1,7 @@
 NC_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
 
 TARGET    ?= host
-TFDIR     ?= $(abspath $(NC_DIR)/../../tensorflow)
+TFDIR     ?= $(abspath /tensorflow)
 PREFIX    ?= /usr/local
 SO_SEARCH ?= $(TFDIR)/bazel-bin/
 
@@ -45,7 +45,7 @@ endif
 
 ifeq ($(TARGET),rpi3)
 TOOLCHAIN   ?= ${TFDIR}/bazel-$(shell basename "${TFDIR}")/external/LinaroArmGcc72/bin/arm-linux-gnueabihf-
-RASPBIAN    ?= $(abspath $(NC_DIR)/../multistrap-raspbian-stretch)
+RASPBIAN    ?= $(abspath $(NC_DIR)/../native_client/msrs)
 CFLAGS      := -march=armv7-a -mtune=cortex-a53 -mfpu=neon-fp-armv8 -mfloat-abi=hard -D_GLIBCXX_USE_CXX11_ABI=0 --sysroot $(RASPBIAN)
 CXXFLAGS    := $(CXXFLAGS)
 LDFLAGS     := -Wl,-rpath-link,$(RASPBIAN)/lib/arm-linux-gnueabihf/ -Wl,-rpath-link,$(RASPBIAN)/usr/lib/arm-linux-gnueabihf/
```

3. From /tensorflow in the Docker container, build the libraries.

```bash
bazel build --config=monolithic --config=rpi3 --config=rpi3_opt --define=runtime=tflite --config=noaws --config=nogcp --config=nohdfs --config=nokafka --config=noignite -c opt --copt=-O3 --copt=-fvisibility=hidden //native_client:libdeepspeech.so //native_client:generate_trie
```

4. Make the deepspeech binary.

```bash
cd /DeepSpeech/native_client
make TARGET=rpi3 deepspeech
file deepspeech
deepspeech: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-, for GNU/Linux 3.2.0, BuildID[sha1]=6c22778c86530d8ef3eebba6dc67a8bfce621827, not stripped
```

5. Copy the files to your host OS and transfer to your Raspberry Pi. You don't technically need the generate_trie for this example, but fine.

```bash
docker cp <container id>:/DeepSpeech/native_client/deepspeech .
docker cp <container id>:/tensorflow/bazel-bin/native_client/libdeepspeech.so .
docker cp <container id>:/tensorflow/bazel-bin/native_client/generate_trie .
scp deepspeech pi@<host>:/deepspeech
scp libdeepspeech pi@<host>:/libdeepspeech.so
scp generate_trie pi@<host>:/generate_trie
```

6. On your Raspberry Pi:

Install dependencies.

```bash
cd
sudo apt-get update && sudo apt-get install libsox-dev libatlas-base-dev swig
git clone https://github.com/mozilla/DeepSpeech.git ds
cd ds
git checkout v0.5.1
python3 -m venv dsvenv
source dsvenv/bin/activate
cp /deepspeech .
sudo cp /libdeepspeech.so /usr/local/lib/libdeepspeech.so
```

Obtain the models and some audio. You may want to SCP the extracted files from your main rig instead to save time.

```bash
curl -LO https://github.com/mozilla/DeepSpeech/releases/download/v0.5.1/deepspeech-0.5.1-models.tar.gz
tar xvf deepspeech-0.5.1-models.tar.gz
curl -LO https://github.com/mozilla/DeepSpeech/releases/download/v0.5.1/audio-0.5.1.tar.gz
tar xvf audio-0.5.1.tar.gz
```

In ~/ds run your tflite-linked deepspeech.

```bash
./deepspeech --model deepspeech-0.5.1-models/output_graph.tflite --alphabet deepspeech-0.5.1-models/alphabet.txt --lm deepspeech-0.5.1-models/lm.binary --trie deepspeech-0.5.1-models/trie --audio audio/2830-3980-0043.wav
```

Time it.

```bash
time ./deepspeech --model deepspeech-0.5.1-models/output_graph.tflite --alphabet deepspeech-0.5.1-models/alphabet.txt --lm deepspeech-0.5.1-models/lm.binary --trie deepspeech-0.5.1-models/trie --audio audio/2830-3980-0043.wav

TensorFlow: v1.13.1-13-g174b4760eb
DeepSpeech: v0.5.1-0-g4b29b78
experienced proof less

real	0m3.211s
user	0m2.140s
sys	0m1.070s
```

Okay, that was a smaller file. Try a 4 second audio clip.

```bash
time ./deepspeech --model deepspeech-0.5.1-models/output_graph.tflite --alphabet deepspeech-0.5.1-models/alphabet.txt --lm deepspeech-0.5.1-models/lm.binary --trie deepspeech-0.5.1-models/trie --audio arctic_a0024.wav
TensorFlow: v1.13.1-13-g174b4760eb
DeepSpeech: v0.5.1-0-g4b29b78
it was my reports from the north which chiefly induced people to buy

real	0m4.744s
user	0m3.740s
sys	0m1.000s
```

Now try a 5 second audio clip.

```bash
time ./deepspeech --model deepspeech-0.5.1-models/output_graph.tflite --alphabet deepspeech-0.5.1-models/alphabet.txt --lm deepspeech-0.5.1-models/lm.binary --trie deepspeech-0.5.1-models/trie --audio test.wav
TensorFlow: v1.13.1-13-g174b4760eb
DeepSpeech: v0.5.1-0-g4b29b78
deep vein thrombosis

real	0m5.055s
user	0m4.027s
sys	0m1.019s
```


Great. We know a nontrivial part of the real running time is ingesting the model files. Let's build up the Python native client and see how much time it takes to inference.

```bash
cd native_client/python
make bindings
pip install dist/deepspeech-0.5.1-cp37-cp37m-linux_armv7l.whl
cd ../../
```

Now let's see how much of the time is in actual inference.

```bash
python native_client/python/client.py --model deepspeech-0.5.1-models/output_graph.tflite --alphabet deepspeech-0.5.1-models/alphabet.txt --lm deepspeech-0.5.1-models/lm.binary --trie deepspeech-0.5.1-models/trie --audio audio/2830-3980-0043.wav
Loading model from file deepspeech-0.5.1-models/output_graph.tflite
TensorFlow: v1.13.1-13-g174b4760eb
DeepSpeech: v0.5.1-0-g4b29b78
Loaded model in 0.00166s.
Loading language model from files deepspeech-0.5.1-models/lm.binary deepspeech-0.5.1-models/trie
Loaded language model in 1.28s.
Running inference.
experienced proof less
Inference took 1.621s for 1.975s audio file.

python native_client/python/client.py --model deepspeech-0.5.1-models/output_graph.tflite --alphabet deepspeech-0.5.1-models/alphabet.txt --lm deepspeech-0.5.1-models/lm.binary --trie deepspeech-0.5.1-models/trie --audio arctic_a0024.wav
Loading model from file deepspeech-0.5.1-models/output_graph.tflite
TensorFlow: v1.13.1-13-g174b4760eb
DeepSpeech: v0.5.1-0-g4b29b78
Loaded model in 0.00199s.
Loading language model from files deepspeech-0.5.1-models/lm.binary deepspeech-0.5.1-models/trie
Loaded language model in 1.28s.
Running inference.
it was my reports from the north which chiefly induced people to buy
Inference took 3.294s for 3.955s audio file.


python native_client/python/client.py --model deepspeech-0.5.1-models/output_graph.tflite --alphabet deepspeech-0.5.1-models/alphabet.txt --lm deepspeech-0.5.1-models/lm.binary --trie deepspeech-0.5.1-models/trie --audio test.wav
Loading model from file deepspeech-0.5.1-models/output_graph.tflite
TensorFlow: v1.13.1-13-g174b4760eb
DeepSpeech: v0.5.1-0-g4b29b78
Loaded model in 0.00171s.
Loading language model from files deepspeech-0.5.1-models/lm.binary deepspeech-0.5.1-models/trie
Loaded language model in 1.28s.
Running inference.
deep vein thrombosis
Inference took 3.583s for 5.000s audio file.
cp deepspeech-0.5.1-models/lm.binary deepspeech-0.5.1-models/lm.binary.copy
```


Terrific. Keep in mind that the there's a filesystem cache. My obvervation is that you need to ensure you've run things once with the .tflite, .binary, and trie so that subsequent runs will be fast. The audio files and alphabet.txt file are really small, so the file system cache plays a neglibible role for those if you're trying to compare runs of a non-warmed up cache versus a warmed up cache. But for a real world application you do want to ensure you've run this once to warm up the file system cache on the big model files. Here's the evidence.


First, the copy.

```bash
cp deepspeech-0.5.1-models/lm.binary deepspeech-0.5.1-models/lm.binary.copy
cp deepspeech-0.5.1-models/output_graph.tflite deepspeech-0.5.1-models/output_graph.tflite.copy
cp deepspeech-0.5.1-models/trie deepspeech-0.5.1-models/trie.copy
cp test.wav test.wav.copy
```

Now, the run with the copied files.

```bash
python native_client/python/client.py --model deepspeech-0.5.1-models/output_graph.tflite.copy --alphabet deepspeech-0.5.1-models/alphabet.txt --lm deepspeech-0.5.1-models/lm.binary.copy --trie deepspeech-0.5.1-models/trie.copy --audio test.wav.copy
Loading model from file deepspeech-0.5.1-models/output_graph.tflite.copy
TensorFlow: v1.13.1-13-g174b4760eb
DeepSpeech: v0.5.1-0-g4b29b78
Loaded model in 0.00188s.
Loading language model from files deepspeech-0.5.1-models/lm.binary.copy deepspeech-0.5.1-models/trie.copy
Loaded language model in 45.3s.
Running inference.
deep vein thrombosis
Inference took 4.703s for 5.000s audio file.
```


Notice how the loading of the language file was slow because the cache wasn't warmed up, but the inference is relatively fast. But the inference is still not quite what we got earlier. Let's see what happens now that we've warmed up the file system cache. To play it safer we'll make a copy of the wave file so that's still an independent variable.

```bash
cp test.wav test.wav.copy.2
python native_client/python/client.py --model deepspeech-0.5.1-models/output_graph.tflite.copy --alphabet deepspeech-0.5.1-models/alphabet.txt --lm deepspeech-0.5.1-models/lm.binary.copy --trie deepspeech-0.5.1-models/trie.copy --audio test.wav.copy.2
Loading model from file deepspeech-0.5.1-models/output_graph.tflite.copy
TensorFlow: v1.13.1-13-g174b4760eb
DeepSpeech: v0.5.1-0-g4b29b78
Loaded model in 0.00196s.
Loading language model from files deepspeech-0.5.1-models/lm.binary.copy deepspeech-0.5.1-models/trie.copy
Loaded language model in 1.28s.
Running inference.
deep vein thrombosis
Inference took 3.598s for 5.000s audio file.
```

Looks good. Have other ways to make this run faster?

## Offline voice based Wikipedia example

If you want to recreate the example from [offline voice based Wikipedia](https://www.icloud.com/sharedalbum/#B0B5ON9t3uAsJR;12EB94FB-FA2D-401E-A7B5-895597BABEB9) you need to install a few more things on your Raspberry Pi 4. I was having problems with espeak so used the festival tool for a simple TTS option. Much more sophisticated options are of course possible.

```bash
sudo apt-get install alsa-utils festival
```

In my case I was using a 3.5mm speaker, so I had to  run raspi-config.

```bash
sudo raspi-config
```

I went to Advanced Options > Audio and set "Force 3.5mm ('headphone') jack" while plugged into a display so the audio wouldn't route to HDMI.

I updated /etc/modules to make it play nicely. Here's what it looks like.

```bash
cat /etc/modules
# /etc/modules: kernel modules to load at boot time.
#
# This file contains the names of kernel modules that should be loaded
# at boot time, one per line. Lines beginning with "#" are ignored.

i2c-dev
snd_bcm2835A
```

Finally, I made a simple Bash script and Python script after fetching some text extracts from English Wikipedia's most read articles for the day. You'll see test-short.bash and lookout.py in the same directory as **this** README.md.

```
curl -O docs.json "https://en.wikipedia.org/w/api.php?action=query&format=json&prop=extracts&generator=mostviewed&exintro=1&explaintext=1&gpvimlimit=500"
bash test-short.bash
```

It would be easy enough to wire up native_client/python/client.py here to inject the language model so that the voice detection runs as fast as possible, but I wanted to just have this run simply for the demo.

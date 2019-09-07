#!/bin/bash

echo "what subject do you want to learn about     i will listen for five seconds"
echo "what subject do you want to learn about     i will listen for five seconds" | festival --tts
arecord -d5 -D plughw:1,0 -f S16_LE -r16000 test.wav 2>/dev/null
searchterms=`./deepspeech-51-tflite-rpi --model deepspeech-0.5.1-models/output_graph.tflite --alphabet deepspeech-0.5.1-models/alphabet.txt --lm deepspeech-0.5.1-models/lm.binary --trie deepspeech-0.5.1-models/trie --audio test.wav 2>/dev/null &`
echo "okay looking"
echo "okay looking" | festival --tts
sleep 3
result=`python lookout.py "$searchterms"`
echo "i think you said $searchterms"
echo "i think you said $searchterms" | festival --tts
sleep 1
echo "result: $result"
echo "$result" | festival --tts

s.boot; // start sound server

(
s.meter;
s.plotTree;
s.scope;
)

b = Buffer.readChannel(s, "/home/sammi/Downloads/Alicia/christina.wav", channels:[0]);

// play the buffer
b.play;

// clear/stop the buffer
b.free;

b.numChannels;

FreqScope.new;

// Define synths/samplers for composition
(
SynthDef(\granSynth, {
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(100),
		0.2,
		b,
		MouseX.kr(0.5,2,1),
		(
			Line.ar(0, BufSamples.ir(b)-1, BufDur.ir(b), doneAction:2)
			+ LFNoise1.ar(100).bipolar(0.01 * SampleRate.ir)
		) / BufSamples.ir(b),
		2,
		0,
		-1,
		512
	);
}).add;
)

s.quit; //kill sound server;
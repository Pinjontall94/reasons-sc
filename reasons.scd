s.boot;

(
s.meter;
s.plotTree;
s.scope;
)

b = Buffer.readChannel(s, "/home/sammi/Downloads/Alicia/christina.wav", channels:[0]);
b.play;

b.numChannels;

FreqScope.new;

(
{
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
	sig = sig * 0.4;
}.play
)
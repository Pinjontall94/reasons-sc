s.boot; // start sound server
s.quit; //kill sound server;

(
s.meter;
s.plotTree;
s.scope;
)

(
b = Buffer.readChannel(
	s,
	"/home/sammi/Downloads/Alicia/christina.wav",
	channels:[0]
);
)

// play the buffer
b.play;

// clear/stop the buffer
b.free;

b.numChannels;

FreqScope.new;

// Define synths/samplers for composition
(
SynthDef(\grnSynth, {
	arg grn_dur=0.2, grn_rate=1, postn_rand=0.01, dens=100, mul=0.3;
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(dens), // trigger
		grn_dur,
		b, // buffer
		grn_rate, // rate
		(
			Line.ar(0, BufSamples.ir(b)-1, BufDur.ir(b), doneAction:2)
			+ LFNoise1.ar(100).bipolar(postn_rand * SampleRate.ir)
		) / BufSamples.ir(b), // position
		2,
		0,
		-1,
		512
	);
	sig = sig * mul;
	Out.ar(0, sig);
}).add;
)

~sources = Bus.audio(s, 2);
~resources = Bus.audio(s, 2);

// Play
(
x = Synth.new(\grnSynth);
)

// Stop
x.free;


// MIDI Stuff

MIDIIn.connectAll;
MIDIIn.disconnectAll;
MIDIFunc.trace(true);
MIDIFunc.trace(false);

(
MIDIdef.cc(\fader1, {
	arg val, num, chan;
	[val, num, chan].postln;
	x.set(\grn_dur, val.linlin(0,127,0.05,0.2));
}, 41).add;

MIDIdef.cc(\fader2, {
	arg val, num, chan;
	[val, num, chan].postln;
	x.set(\grn_rate, val.linlin(0,127,0,1));
}, 42).add;

MIDIdef.cc(\fader3, {
	arg val, num, chan;
	[val, num].postln;
	x.set(\dens, val.linlin(0,127,50,300));
}, 43).add;

MIDIdef.cc(\fader4, {
	arg val, num, chan;
	[val, num].postln;
	x.set(\postn_rand, val.linlin(0,127,0.01,1));
}, 44).add;
)


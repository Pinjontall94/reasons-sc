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

b.stop;
// clear/stop the buffer
b.free;

b.numChannels;

FreqScope.new;

// Define synths/samplers for composition
(
// Basic Sine tone to test audio routing and FX
SynthDef(\test, {
	arg out=0, freq=440, mul=0.3;
	var sig;
	sig = SinOsc.ar(freq, 0, mul);
	Out.ar(out, sig);
}).add;

SynthDef(\gs, {
	arg out=0, grn_dur=0.2, grn_rate=1, postn_rand=0.01, dens=100, mul=0.3;
	var sig;
	sig = GrainBuf.ar(
		2,
		trigger: Impulse.ar(dens),
		dur: grn_dur,
		sndfbuf: b,
		rate: grn_rate,
		pos: (
			Line.ar(0, BufSamples.ir(b)-1, BufDur.ir(b), doneAction:2)
			+ LFNoise1.ar(100).bipolar(postn_rand * SampleRate.ir)
		) / BufSamples.ir(b), // position
		interp: 2, // linear
		pan: 0,
		envbufnum: -1, // use built-in Hann envelope
		maxGrains: 512
	);
	sig = sig * mul;
	Out.ar(out, sig);
}).add;

Synthdef(\del, {
	arg out=0, in, deltime=0.3, mix=(-0.5), amp=1; //decay=3
	var sig, del;
	sig = In.ar(in, 1) * amp;
	del = DelayL.ar(
		sig,
		0.5,
		deltime,
		//decay
	);
	sig = XFade2.ar(sig, del, mix)
	Out.ar(out, sig);
}).add;
)

~delBus = Bus.audio(s, 1);

// Play
(
~gsGrp = Group.new;
~delGrp = Group.after(~gsGrp);

~del = Synth.new(\del, [\out, 0, \in, ~delBus], ~delGrp);
~gsFX = Synth.new(\gs, [\out, ~delBus], ~gsGrp);
~gsDirect = Synth.new(\gs[\out, 0], ~gsGrp);
)

// Stop
~playback.free;


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

(
{DelayL.ar(
	in: SinOsc.ar(440, 0, 0.05)!2,
	maxdelaytime: 0.5,
	delaytime: SinOsc.kr().exprange(0.35,0.4),
	//decaytime: 2,
)}.play;
)
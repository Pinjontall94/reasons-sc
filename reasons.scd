// Start Audio & MIDI
(
s.boot;
MIDIIn.connectAll;
)

// Quit
(
MIDIIn.disconnectAll;
s.quit; //kill sound server;
)

// Recording
s.prepareForRecord("~/Recordings/test9.wav", numChannels: 2); // NOTE: Call before s.record!

s.record;

s.pauseRecording; // pausable

s.stopRecording; // closes file & deallocates the buffer, recording node, etc.

// Initialize monitors
(
s.meter;
s.plotTree;
s.scope;
)

// MIDI Debug
MIDIFunc.trace(true);
MIDIFunc.trace(false);



// Read wav file to buffer 'b'
(
b = Buffer.readChannel(
	s,
	"/home/sammi/Downloads/Alicia/christina.wav",
	channels:[0]
);
)
// play the buffer
b.stop;

// clear/stop the buffer
b.free;

b.numChannels;

FreqScope.new;


// Synths for signal generation
(
// Basic Sine tone to test audio routing and FX
SynthDef(\test, {
	arg out=0, freq=440, mul=0.1;
	var sig;
	sig = SinOsc.ar(freq, 0, mul)!2;
	Out.ar(out, sig);
}).add;

// Main granular synth for buffer playback
SynthDef(\gs, {
	arg out=0, buf=b, dur=0.2, durRand=1, rate=1, pos=0, posRate=1,
	posRand=0.01, dens=100, pan=0, panHz=0.1, panRand=0, mul=0.3;
	var sig, durCntrl, panCntrl, posCntrl;

	durCntrl = dur + LFNoise1.kr(100).exprange(1/durRand,durRand);
	posCntrl = Phasor.ar(0, posRate * BufRateScale.ir(buf), 0, BufSamples.ir(buf) - 1);
	posCntrl = posCntrl + LFNoise1.kr(100).bipolar(posRand * SampleRate.ir);
	posCntrl = posCntrl / BufSamples.ir(buf);
	panCntrl = pan + LFNoise1.kr(panHz).bipolar(panRand);

	sig = GrainBuf.ar(
		2,
		Impulse.ar(dens),
		durCntrl,
		buf,
		rate,
		posCntrl, // position
		2, // linear
		panCntrl,
		-1, // use built-in Hann envelope
		512
	);
	sig = sig * mul;
	Out.ar(out, sig);
}).add;


// FX Section
SynthDef(\srr, {
	arg out=0, in, rate=20000;
	var sig, srr;
	sig = In.ar(in, 2);
	srr = Latch.ar(sig, Impulse.ar(rate));
	Out.ar(out, srr);
}).add;

SynthDef(\bp, {
	arg out=0, in, freq=440, rq=1, mul=1;
	var sig, filter;
	sig = In.ar(in, 2);
	filter = BPF.ar(sig, freq, rq, (1 / rq)) * mul;
	Out.ar(out, filter);
}).add;

SynthDef(\dist, {
	|out=0, in, amp=100, mul=1, bypass=0|
	var sig, dist, final;
	sig = In.ar(in, 2) * amp;
	dist = sig * amp;
	dist = dist.tanh;
	final = Select.ar(bypass, [dist,sig]);
	final = final * mul;
	Out.ar(out, sig);
}).add;

SynthDef(\folder, {
	arg out=0, in, amp=100, mul=1;
	var sig;
	sig = In.ar(in, 2) * amp;
	sig = sig.fold2 / amp * mul;
	Out.ar(out, sig);
}).add;

SynthDef(\del, {
	arg out=0, in, modDepth=0.2, modOffset=0.4,
	randRate=1, randAmnt=1, modRate=0.3;
	var sig, del, delayCntrl;

	delayCntrl = SinOsc.ar(
		LFNoise1.ar(randRate, randAmnt, modRate),
		0,
		modDepth.lag(0.1),
		modOffset
	);

	sig = In.ar(in, 2);
	del = DelayC.ar(sig,0.6,delayCntrl);
	Out.ar(out, del);
}).add;

SynthDef(\reverb, {
	arg out=0, in, mix=0.33, room=0.5, damp=0.5, amp=1, bpfreq=1000, bprq=1.0,
	mul=0.3;
	var sig, verb, bp;
	sig = In.ar(in, 2) * amp;
	bp = BPF.ar(sig, bpfreq.lag(0.1), bprq);
	verb = FreeVerb2.ar(bp[0], bp[1], mix, room, damp, mul);
	Out.ar(out, verb);
}).add;

SynthDef(\masterVol, {
	|out=0, in, mul=1|
	var sig;
	sig = In.ar(in, 2) * Lag.kr(mul, 0.1);
	Out.ar(out, sig);
}).add;
)

// BUSSES - Dedicated private audio busses (i.e. cables between // each synth)
(
//~srrBus = Bus.audio(s, 2);
//~distBus = Bus.audio(s, 2);
//~folderBus = Bus.audio(s, 2);
~delBus = Bus.audio(s, 2);
~verbBus = Bus.audio(s, 2);
~masterBus = Bus.audio(s, 2);
)


// ROUTING
// Make sure you go latest to earliest in signal chain, top to
// bottom
(
~playbackGrp = Group.new;
~fxGrp = Group.after(~playbackGrp);
)

(
~masterVol.free;
~masterVol = Synth.new(\masterVol, [
	\out, 0,
	\in, ~masterBus,
	\mul, ~fd9.linexp(0,127,0.0001,1);
], ~fxGrp);

~verb.free;
~verb = Synth.new(
	\reverb,
	[
		\out, ~masterBus,
		\in, ~verbBus,
//		\bpfreq, ~fd5.linlin(0,127,20,20000),
//		\damp, ~fd6.linlin(0,127,0,1),
//		\mix, ~fd7.linlin(0,127,0,1),
//		\room, ~fd8.linexp(0,127,0,1),
		\mul, 1
	],
~fxGrp);

~del.free;
~del = Synth.new(
	\del,
	[
		\out, 0,
		\in, ~delBus,
//		\randRate, ~fd3.linlin(0,127,0,2),
//		\randAmnt, ~fd4.linlin(0,127,0,2),
//		\modRate, ~fd1.linlin(0,127,0,2),
//		\modDepth, ~fd2.linlin(0,127,0,0.0025),
//		\modOffset, 0.0075,
//		\mix, (1), // -1 = sig, 1 = del
//		\amp, 1
	],
	~fxGrp
);
)

(
MIDIdef.cc(\fader1, {
	|val| ~del.set(\modRate, val.linexp(0,127,0.0001,10));
	~fd1 = val;
}, 41).add;

MIDIdef.cc(\fader2, {
	|val| ~del.set(\modDepth, val.linlin(0,127,0,0.2));
	~fd2 = val;
}, 42).add;

MIDIdef.cc(\fader3, {
	|val| ~del.set(\randRate, val.linlin(0,127,0,2));
	~fd3 = val;
}, 43).add;

MIDIdef.cc(\fader4, {
	|val| ~del.set(\randAmnt, val.linlin(0,127,0,2));
	~fd4 = val;
}, 44).add;

MIDIdef.cc(\fader5, {
	|val| ~verb.set(\bpfreq, val.linlin(0,127,20,20000));
	~fd5 = val;
}, 45).add;

MIDIdef.cc(\fader6, {
	|val| ~verb.set(\damp, val.linlin(0,127,0.0001,1));
	~fd6 = val;
}, 46).add;

MIDIdef.cc(\fader7, {
	|val| //~verb.set(\mix, val.linlin(0,127,0,1));
	~fd7 = val;
}, 47).add;

MIDIdef.cc(\fader8, {
	|val| //~verb.set(\room, val.linexp(0,127,0,1));
	~fd8 = val;
}, 47).add;

MIDIdef.cc(\fader9Master, {
	|val| ~masterVol.set(\mul, val.linexp(0,127,0.001,1));
	~fd9 = val;
}, 7).add;

MIDIdef.cc(\knob1, {
	|val| ~gs.set(\dur, val.linlin(0,127,0.001,0.2));
	~kn1 = val;
}, 21).add;

MIDIdef.cc(\knob2, {
	|val| ~gs.set(\rate, val.linlin(0,127,0,1));
	~kn2 = val;
}, 22).add;

MIDIdef.cc(\knob3, {
	|val| ~gs.set(\dens, val.linlin(0,127,50,300));
	~kn3 = val;
}, 23).add;

MIDIdef.cc(\knob4, {
	|val| ~gs.set(\panHz, val.linlin(0,127,0.1,100));
	~kn4 = val;
}, 24).add;

MIDIdef.cc(\knob5, {
	|val| ~gs.set(\panRand, val.linlin(0,127,0,1));
	~kn5 = val;
}, 25).add;

MIDIdef.cc(\knob6, {
	|val| ~gs.set(\posRand, val.linlin(0,127,0.01,1));
	~kn6 = val;
}, 26).add;

MIDIdef.cc(\knob7, {
	|val| ~gs.set(\posRate, val.linlin(0,127,-1,1));
	~kn7 = val;
}, 27).add;

MIDIdef.cc(\knob8, {
	|val| ~gs.set(\mul, val.linlin(0,127,0.0001,1));
	~kn8 = val;
}, 28).add;
)

(
~gs = Synth.new(\gs, [\out, 0]);
)
~test = Synth.new(\test, [\out, ~masterBus], ~playbackGrp);


//		\dur, ~kn1,
//		\rate, ~kn2,
//		\dens, ~kn3,
//		\panHz, ~kn4,
//		\panRand, ~kn5,
//		\posRand, ~kn6,
//		\posRate, ~kn7,
//		\mul, 1

// GAMEPLAN
/*
1. Hardcode bp to reasonable "boombox quality", add to reverb synthgen
2. Draft I: gs -> del -> verb -> master -> recorder
3. Create momentary triggers for distortion, folder, sample rate reducer
	i. MIDIdef.cc(\momentaryFX, {
		|va| ~fx.set(\param, val.clip(1)); // clip 0<->127 cc signal to 0<->1
	}, ccNum: #).add;
4. Create fx on/off switches in SC, place towards the bottom for easy access
5. Draft II: gs -> dist -> verb -> master -> recorder
6. Add momentary triggers for folder & sample rate reducer
*/


// Stop test tones
(
~test.free;
~gs.free;
)
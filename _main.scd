(//server config
s = Server.local;
s.newBusAllocators;
ServerBoot.removeAll;
ServerTree.removeAll;
ServerQuit.removeAll;

o = Server.default.options;
o.blockSize_(512);
o.inDevice_("JackRouter"); //MME : Speakers
o.outDevice_("JackRouter");//ASIO : US-2x2 & US-4x4
o.memSize = 2.pow(15);

//global var
~tempo = TempoClock.new(149/60, 7).permanent_(true);
~scale = [
	Scale.dorian, Scale.hexPhrygian, Scale.hungarianMinor, Scale.ionian,
	Scale.partch_o1, Scale.mixolydian, Scale.superLocrian, Scale.marva,
	Scale.partch_o5, Scale.yakahDesc, Scale.suznak, Scale.romanianMinor,
];

~bufPath = PathName(thisProcess.nowExecutingPath).parentPath++"buf/";
~scapePath = PathName(thisProcess.nowExecutingPath).parentPath++"scapes/";

~times = [rrand(10, 15), rrand(40, 70), rrand(75, 105), rrand(110, 145), rrand(150, 180), rrand(185, 315), rrand(320, 350), rrand (355, 380)];

//global func
~chrono = { //from Andrea Valle
	var w, x = 200, y = 200, title = "Tempus fugit"  ; // GUI var
	var clockField ;
	var r, startTime = thisThread.seconds ; // scheduling

	w = Window.new(title, Rect(x, y, 400, 120)) ;
	clockField = StaticText.new(w, Rect(1,1, 400, 120))
	.align_(\center)
	.stringColor_(Color(1.0, 0.0, 0.0))
	.background_(Color(0,0,0))
	.font_(Font(Font.defaultMonoFace, 48));
	r = Routine.new({
		loop({
			clockField.string_((thisThread.seconds-startTime)
				.asInteger.asTimeString) ;
			1.wait })
	}).play(AppClock) ;
	w.front ;
	w.onClose_({ r.stop }) ;
};

~arrFunc = { |array, weights, num|
	var result = Array(num), i;
	weights = weights.copy;
	min(weights.size, num).do {
		i = weights.windex;
		result = result.add(array[i]);
		weights = weights.put(i, 0).normalizeSum;
	};
	result
};

~times_1 = ~arrFunc.(~times + rrand(0, 10), [8, 2, 3, 10, 5, 8, 2, 0.1].normalizeSum, rrand(1, 2));
~stops_1 = ~times_1 + Array.fill(~times_1.size, {rrand(30, 60.0)});

~times_2 = ~arrFunc.(~times + rrand(-5, 15), [0.1, 0.2, 4, 8, 10, 5, 1, 0.1].normalizeSum, 1);
~stops_2 = ~times_2 + Array.fill(~times_2.size, {rrand(60, 80.0)});

~times_3 = ~arrFunc.(~times + rrand(-5, 20), [0.2, 7, 0.2, 4, 6, 8, 6, 1].normalizeSum, rrand(1, 2));
~stops_3 = ~times_3 + Array.fill(~times_3.size, {rrand(40, 60.0)});

~atimes = ~arrFunc.(~times + rrand(0, 5), [10, 0.1, 0.5, 2, 3, 0.1, 0.1, 10].normalizeSum, rrand(1, 2));
~astops = ~atimes + Array.fill(~atimes.size, {rrand(40, 60)});

~btimes = ~arrFunc.(~times + rrand(-5, 15), [1, 0.4, 0.2, 6, 10, 0.3, 7, 0.1].normalizeSum, 2);
~bstops = ~btimes + Array.fill(~btimes.size, {rrand(40, 80)});

~stimes = ~arrFunc.(~times + rrand(0, 20), [6, 1, 0.3, 6, 1, 4, 0.5, 10].normalizeSum, rrand(2, 3));
~sstops = ~stimes + Array.fill(~stimes.size, {rrand(80.0, 120)});

~makeBusses = s.makeBundle(s.latency, {
	~delBus = Bus.audio(s,2);
	~revBus = Bus.audio(s,2);
	~textBus = Bus.audio(s,2);
	~bufBus = Bus.audio(s,2);
	~bpBus = Bus.audio(s, 2);
	~scapeBus = Bus.audio(s, 2);
	~masterBus = Bus.audio(s,2);
});

~makeNodes = {
	s.bind(
		~srcGrp = Group.new;
		~bufGrp = Group.after(~srcGrp);
		~fxGrp = Group.after(~bufGrp);
		~msGrp = Group.after(~fxGrp);
		s.sync;
		~revSynth = Synth.new(\rev, [\in, ~revBus, \out, ~textBus], ~fxGrp, \addToTail);
		~delSynth = Synth.before(~revSynth, \delay, [\in, ~delBus, \out, ~revBus], ~fxGrp, \addToTail);
		~textMix = Synth.new(\textMix, [\in, ~textBus, \out, ~masterBus, \vol, 0.4], ~msGrp);
		~bufMix = Synth.after(~textMix, \bufMix, [\in, ~bufBus, \out, ~scapeBus, \vol, 2.2]);
		~scapeMix = Synth.after(~bufMix, \scapeMix, [\in, ~scapeBus, \out, ~masterBus, \vol, 1.5]);
		~masterSynth = Synth.new(\master, [\in, ~masterBus, \vol, 0.3], ~msGrp, \addToTail);
	)
};

~cleanUp = {
	s.newBusAllocators;
	ServerBoot.removeAll;
	ServerTree.removeAll;
	ServerQuit.removeAll;
};

~makeBuffers={
	var arrSqu, arrSaw;
	var sigSqu, sigSaw, sigSin, sigRand;

	arrSqu = {
		var arr;
		arr = Array.fill(2.pow(14).asInteger, {|i|
			i = i+1;
			if(i.odd){
				i = 1/i;
			}
			{i = 1}}
		);
		arr = arr * 0.75
	};
	sigSqu = Signal.sineFill(
		2.pow(14).asInteger,
		arrSqu.value,
		0!8192);
	arrSaw = {
		var arr;
		arr = Array.fill(2.pow(14).asInteger, {|i|
			i = i+1;
			i = 1/i;
		});
		arr = arr * 0.5
	};
	sigSaw = Signal.sineFill(
		2.pow(14).asInteger,
		arrSaw.value,
		0!8192);
	sigSin = Signal.sineFill(
		2.pow(14).asInteger,
		[1],
		[0]);
	sigRand = Env(
		{rrand(-1, 1)}!14,
		{exprand(1, 20)}!15,
		{rrand(1, 20)}!15
	).asSignal(2.pow(14).asInteger);

	~bufSin = Buffer.alloc(s, (2.pow(15)).asInteger);
	~bufSqu = Buffer.alloc(s, (2.pow(15)).asInteger);
	~bufSaw = Buffer.alloc(s, (2.pow(15)).asInteger);
	~bufRand = Buffer.alloc(s, (2.pow(15)).asInteger);

	~bufSin.loadCollection(sigSin.asWavetable);
	~bufSqu.loadCollection(sigSqu.asWavetable);
	~bufSaw.loadCollection(sigSaw.asWavetable);
	~bufRand.loadCollection(sigRand.asWavetable);
};

~makeRhythmBuffers={
	b = Dictionary.new;
	PathName(~bufPath.asString).entries.do{
		arg subfolder;
		b.add(
			subfolder.folderName.asSymbol ->
			Array.fill(
				subfolder.entries.size,
				{
					arg i;
					Buffer.read(s, subfolder.entries[i].fullPath);
				}
			)
		);
	};
	~kickDir = b[\kick];
	~hihatDir = b[\hihat];
	~snareDir = b[\snare];
	~sinesDir = b[\sines];
};

~makeScapes={
	d = Dictionary.new;
	PathName(~scapePath.asString).entries.do{
		arg subfolder;
		d.add(
			subfolder.folderName.asSymbol ->
			Array.fill(
				subfolder.entries.size,
				{
					arg i;
					Buffer.read(s, subfolder.entries[i].fullPath);
				}
			)
		);
	};
	~scapesDir = d[\all];
};

~texture_1 = { |start, stop|
	var synthi, scale, chords;

	scale = ~scale.choose;
	chords = 16.collect{
		scale.degreeToFreq(scale.degrees.choose,
			(if(rrand(0,1).coin,
				rrand(3.1, 18),
				rrand(98, 127))
			),
			(if(rrand(0,1).coin,
				(rrand(0.01, 0.6)),
				(rrand(4.5, 5)))
			)
		).clip(1, 18000)
	};

	SystemClock.sched(start-30, {
		("next Texture at "++start.asTimeString).postln;
	});
	SystemClock.sched(start, {
		("Texture_1 at "++start.asTimeString).postln;
		synthi = Array.fill(16, {
			Synth.new(\vOsc, [
				\freq, chords.choose,
				\amp, rrand(0.01, 0.25),
				\dly, rrand(0.001, 15),
				\atk, if(rrand(0, 0.0005).coin, 0, rrand(15.0, 35)),
				\dcy, rrand(4.5, 12),
				\sus, rrand(0.2, 0.6),
				\rel, if(rrand(0, 0.1).coin, 0, rrand(10.0, 35)),
				\crv, rrand(-9, 6.5),
				\pos, rrand(0.5, 2.7),
				\cutoff, rrand(6000, 15000),
				\detuneAmount, rrand(0.001, 0.55),
				\jitAmount, rrand(0.001, 0.2),
				\buf, ~bufSin.bufnum,
				\out, ~textBus,
				\rev, rrand(0, 0.99),
				\revOut, ~revBus,
				\del, rrand(0, 0.2),
				\delOut, ~delBus
			], ~srcGrp
		)});
	});

	SystemClock.sched(stop, {
		synthi.do(_.set(\gate, 0));
	});
	SystemClock.sched(stop-30, {
		("Texture stops at "++stop.asTimeString).postln;
	});
};//texture ends

~texture_2 = { |start, stop|
	var pSynthi;

	SystemClock.sched(start-30, {
		("next Texture at "++start.asTimeString).postln;
	});
	SystemClock.sched(start, {
		("Texture_2 at "++start.asTimeString).postln;
		pSynthi = Pbind(
			\instrument, \vOsc,
			\dur, Pwhite(0.08, 0.9, inf),
			\midinote, 2,
			\harmonic, Pwhite(1, 80, inf),
			\dly, Pexprand(0.00001, 1.5, inf),
			\atk, Pwhite(3, 14.0, inf),
			\dcy, Pwhite(4, 10.0, inf),
			\rel, Pwhite(3, 11.0, inf),
			\crv, Pexprand(0.1, 6, inf) * Prand([1, -1,], inf),
			\amp, Pwhite(0.1, 2, inf),
			\pos, 0,
			\detuneAmount, Pwhite(0.0001, 0.1, inf),
			\jitAmount, Pwhite(0.00001, 0.00002, inf),
			\cutoff, Pwhite(9000, 18000, inf),
			\buf, ~bufSin.bufnum,
			\out, ~textBus,
			\group, ~srcGrp,
			\rev, Pwhite(0, 0.2, inf),
			\revOut, ~revBus,
			\del, Pwhite(0, 0.2, inf),
			\delOut, ~delBus
		).play;
	});

	SystemClock.sched(stop, {
		pSynthi.stop
	});
	SystemClock.sched(stop-30, {
		("Texture stops at "++stop.asTimeString).postln;
	});
};//texture ends

~texture_3 = { |start, stop|
	var synthi, bpf, scale, chords;

	scale = ~scale.choose;
	chords = 16.collect{
		scale.degreeToFreq(scale.degrees.choose,
			(if(rrand(0,1).coin,
				rrand(3.1, 18),
				rrand(98, 127))
			),
			(if(rrand(0,1).coin,
				(rrand(0.01, 0.6)),
				(rrand(4.5, 5)))
			)
		).clip(0.1, 18000)
	};

	SystemClock.sched(start-30, {
		("next Texture at "++start.asTimeString).postln;
	});
	SystemClock.sched(start, {
		("Texture_3 at "++start.asTimeString).postln;
		bpf = Array.fill(16, {Synth(\BPF, [\in, ~bpBus, \out, ~textBus,
			\freq, exprand(120, 18000),
			\jit, exprand(1, 0.5),
			\rq, exprand(0.001, 2.sqrt),
			\mix, 1,
			\gain, 6,
			\amp, 1,
		], ~fxGrp, \addToHead
		)});
		synthi = Array.fill(4, {
			Synth.new(\vOsc, [
				\freq, chords.choose,
				\amp, rrand(0.05, 0.2),
				\dly, rrand(0.001, 1.5),
				\atk, if(rrand(0, 0.0001).coin, 0, rrand(15.0, 35)),
				\dcy, rrand(6.1, 15.3),
				\sus, rrand(0.2, 0.6),
				\rel, if(rrand(0, 0.1).coin, 0, rrand(10.0, 35)),
				\crv, rrand(-6, 9.0),
				\pos, rrand(0.5, 2.7),
				\cutoff, rrand(6000, 18000),
				\detuneAmount, rrand(0.01, 0.55),
				\jitAmount, rrand(0.001, 0.2),
				\buf, ~bufSin.bufnum,
				\bpf, rrand(0.1, 0.8),
				\bpfOut, ~bpBus,
				\out, ~textBus,
				\rev, rrand(0, 0.99),
				\revOut, ~revBus,
				\del, rrand(0, 0.2),
				\delOut, ~delBus
			], ~srcGrp
		)});
	});

	SystemClock.sched(stop, {
		synthi.do(_.set(\gate, 0));
	});
	SystemClock.sched(stop+20, {
		bpf.do(_.set(\gate, 0));
	});
	SystemClock.sched(stop-30, {
		("Texture stops at "++stop.asTimeString).postln;
	});
};//texture ends

~angryTexture = { |start, stop|
	var synthi, scale, chords;

	scale = ~scale.choose;
	chords = 16.collect{
		scale.degreeToFreq(scale.degrees.choose,
			(if(rrand(0,1).coin,
				rrand(3.1, 18),
				rrand(98, 127))
			),
			(if(rrand(0,1).coin,
				(rrand(0.01, 0.6)),
				(rrand(4.5, 5)))
			)
		).clip(0.1, 18000)
	};

	SystemClock.sched(start-30, {
		("next angryTexture at "++start.asTimeString).postln;
	});
	SystemClock.sched(start, {
		("angryTexture at "++start.asTimeString).postln;
		synthi = Array.fill(24, {
			Synth.new(\vOsc,
				if(rrand(0,1).coin, [
					\freq, chords.normalize(45, 90).choose,
					\pos, rrand(0.5, 1.5),
					\cutoff, rrand(45, 180),],
				[
					\freq, chords.normalize(6000, 18000).choose,
					\pos, rrand(0.5, 2.7),
					\cutoff, rrand(9000, 18000),]) ++ [
					\amp, rrand(0.25, 0.5),
					\atk, rrand(0, 0.1),
					\dcy, rrand(9, 19.1),
					\sus, rrand(0.3, 0.8),
					\rel, 0,
					\crv, rrand(-9, 6),
					\detuneAmount, rrand(0.001, 0.55),
					\jitAmount, rrand(0.001, 0.2),
					\buf, ~bufSin.bufnum,
					\out, ~textBus,
					\rev, rrand(0, 0.2),
					\revOut, ~revBus,
					\del, rrand(0, 0.05),
					\delOut, ~delBus
				]
				, ~srcGrp
		)});
	});

	SystemClock.sched(stop, {
		synthi.do(_.set(\gate, 0));
	});
	SystemClock.sched(stop-30, {
		("angryTexture stops at "++stop.asTimeString).postln;
	});
};//texture ends

~rhythm = { |start, stop|
	var kick, snare, hihat, sines;

	SystemClock.sched(start-30, {
		("next Rhythm at "++start.asTimeString).postln;
	});
	SystemClock.sched(start+(rrand(0,5)), {
		("rhythm at "++start.asTimeString).postln;
		kick = Pbind(
			\instrument, \rhythmBuf,
			\dur, Prand([
				Pwrand([1/4, Rest(1/4)], [0.8, 0.1], inf),
				Pseq([1, Rest(1)], inf)]),
			\amp, Pseq([2, Pwhite(0.01, 1.5, 6)], inf),
			\buf, ~kickDir[0],
			\rate, Pwhite(0.95, 1.35, inf),
			\pan, Pwhite(-0.2, 0.2, inf),
			\out, ~bufBus,
			\group, ~bufGrp,
			\del, Prand([
				0,
				Pexprand(0.0001, 1.0, inf)
			], inf),
			\delOut, ~delBus
		).play(~tempo, quant:1);
	});
	SystemClock.sched(start+(rrand(4,11)), {
		sines = Pbind (
			\instrument, \rhythmBuf,
			\dur, Prand([
				Pwrand([1/4, Rest(1/4)], [0.01, 0.09].normalizeSum, inf),
				Pwrand([1/4, Rest(1/4)], [0.9, 0.1].normalizeSum, inf)
			], inf),
			\amp, Pwhite(0.005, 0.3, inf),
			\buf, ~sinesDir[[0,1].choose],
			\rate, Pwhite(0.0001, 13, inf),
			\pan, Pwhite(-1.0, 1.0, inf),
			\out, ~bufBus,
			\group, ~bufGrp,
			\del, Prand([
				0,
				Pexprand(0.0001, 0.5, inf)
			], inf),
			\delOut, ~delBus
		).play(~tempo, quant:1);
	});
	SystemClock.sched(start+(rrand(2,9)), {
		snare = Pbind (
			\instrument, \rhythmBuf,
			\dur, Pwrand([1/8, Rest(1/8)], [0.1, 0.9], inf),
			\amp, Pwhite(0.00001, 0.25, inf),
			\buf, Prand([~snareDir[0], ~snareDir[1], ~snareDir[2]], inf),
			\rate, Pwhite(1.3, 2, inf),
			\pan, Pwhite(-1.0, 1.0, inf),
			\out, ~bufBus,
			\group, ~bufGrp,
			\del, Prand([
				0,
				Pexprand(0.0001, 0.5, inf)
			], inf),
			\delOut, ~delBus
		).play(~tempo, quant:1);
	});
	SystemClock.sched(start+(rrand(0,7)), {
		hihat = Pbind (
			\instrument, \rhythmBuf,
			\dur, Pwrand([1/4, Rest(1/4)], [0.98, 0.02], inf),
			\amp, Pwhite(0.0001, 0.7, inf),
			\buf, Prand([~hihatDir[0],~hihatDir[1],~hihatDir[2],~hihatDir[3]], inf),//~hihatDir[(0..3)]
			\rate, Pwhite(1, 16, inf),
			\pan, Pwhite(-1.0, 1.0, inf),
			\out, ~bufBus,
			\group, ~bufGrp,
			\del, Prand([
				0,
				Pexprand(0.0001, 0.5, inf)
			], inf),
			\delOut, ~delBus
		).play(~tempo, quant:1);
	});//start schedule ends

	SystemClock.sched(stop+(rrand(-15, 15)), {
		kick.stop;
	});
	SystemClock.sched(stop+(rrand(-30, 0)), {
		snare.stop;
	});
	SystemClock.sched(stop+(rrand(-5, 20)), {
		hihat.stop;
	});
	SystemClock.sched(stop+(rrand(-5, 15)), {
		sines.stop;
	});

	SystemClock.sched(stop-30, {
		("Rhythm stops at "++stop.asTimeString).postln;
	});


};//rhythm ends

~scapes= { |start, stop|
	var scapestrato, bpSynth,
	samples = [~scapesDir.[(0..5).choose], ~scapesDir.[(0..5).choose]];

	SystemClock.sched(start-30, {
		("next scape at "++start.asTimeString).postln;
	});
	SystemClock.sched(start, {
		("scapes at "++start.asTimeString).postln;
		bpSynth = Array.fill(8, {Synth(\BPF, [\in, ~bpBus, \out, ~scapeBus,
			\freq, exprand(120, 18000),
			\jit, exprand(1, 0.5),
			\rq, exprand(0.001, 2.sqrt),
			\mix, rrand(-0.5, 1),
			\gain, 2,
			\amp, 1/4,
		], ~fxGrp, \addToHead
		)});
		scapestrato = Array.fill(12, {
			Synth.new(\fieldBuf, [
				\rate, if(rrand(0.75, 1).coin,
					exprand(0.85, 1.5),
					rrand (0.1, 5)),
				\amp, if(rrand(0.15, 1).coin,
					rrand(0.5, 1),
					0),
				\dly, rrand(0.1, 15),
				\atk, exprand(15, 29.0),
				\dcy, rrand(5, 20.5),
				\sus, rrand(0.1, 0.6),
				\rel, if(rrand(0, 0.01).coin, 0, rrand(10, 20.5)),
				\crv, rrand(2, 9.0) * [-1,1].choose,
				\buf, samples.choose,
				\out, ~bpBus,
				\del, rrand(0, 0.5),
				\delOut, ~delBus
			], ~bufGrp;
		)});
	});//start schedule ends

	SystemClock.sched(stop, {
		scapestrato.do(_.set(\gate, 0));
	});
	SystemClock.sched(stop+15, {
		bpSynth.do(_.set(\gate, 0))
	});
	SystemClock.sched(stop-30, {
		("Scapes stops at "++stop.asTimeString).postln;
	});
};//scape ends

//register funcs
ServerBoot.add(~makeBuffers);
ServerBoot.add(~makeScapes);
ServerBoot.add(~makeRhythmBuffers);
ServerBoot.add(~makeBusses);
ServerQuit.add(~cleanUp);

//boot
s.waitForBoot({

	SynthDef.new(\vOsc, {
		arg buf=0, numBufs=4, pos= 1.0,
		freq = 300, amp = 0.9, detuneAmount = 0.001, jitAmount=0.001, cutoff = 12000,
		atk=0.001, dcy=0.2, sus = 1.0, rel = 0.4, dly=0.0, crv=1,
		bpf = 0, bpfOut = 0, rev = 0, revOut = 0, del = 0, delOut = 0,
		gate = 1, out=0;
		var sig, env, bufpos, jitter, detuneSig;
		jitter = LFNoise0.kr(jitAmount, jitAmount, jitAmount);
		bufpos = buf + pos + jitter;
		detuneSig = LFNoise1.kr(0.02!4).bipolar(detuneAmount).midiratio.lag(0.5);
		env = EnvGen.kr(Env.dadsr(dly, atk, dcy, sus, rel, curve:crv), gate, doneAction:2);
		sig = VOsc.ar(bufpos.clip(buf+0.1, numBufs-0.1), freq*(detuneSig).lag(0.3));
		sig = Splay.ar(sig) * env * amp;
		sig = LPF.ar(sig, cutoff);
		Out.ar(out, sig);
		Out.ar(bpfOut, sig * bpf);
		Out.ar(revOut, sig * rev);
		Out.ar(delOut, sig * del);
	}).add;

	SynthDef.new(\rhythmBuf, {
		arg atk=0.00001, sus=1, rel=0.2,
		buf=0, rate=1,
		del = 0, delOut = 0,
		amp=1, out=0, pan=0;
		var sig, env;
		env = EnvGen.kr(Env([0,1,1,0],[atk,sus,rel],), doneAction:2);
		sig = PlayBuf.ar(1, buf, rate*BufRateScale.ir(buf));
		sig = sig - OnePole.ar(sig, exp(-2pi * (50 * SampleDur.ir)));
		sig = sig*env*amp;
		sig = Pan2.ar(sig, pan);
		Out.ar(out,sig);
		Out.ar(delOut, sig * del);
	}).add;

	SynthDef(\fieldBuf, {
		arg dly=0.0001, atk=0.3, sus=1, dcy=1, rel=0.3, crv=1,
		buf=0, rate=1, gate=1,
		del = 0, delOut = 0,
		amp=1, out=0, pan=0;
		var sig, env;
		env = EnvGen.kr(Env.dadsr(dly, atk, dcy, sus, rel, curve:crv), gate, doneAction:2);
		sig = PlayBuf.ar(2, buf, rate*BufRateScale.ir(buf), loop: 1);
		sig = sig - OnePole.ar(sig, exp(-2pi * (120 * SampleDur.ir))); //http://tiny.cc/4462gz
		sig = sig*env*amp;
		Out.ar(out,sig);
		Out.ar(delOut, sig * del);
	}).add;

	SynthDef(\rev, {
		arg in, out;
		var sig, rev;
		sig = In.ar(in, 2);
		sig = sig - OnePole.ar(sig, exp(-2pi * (120 * SampleDur.ir)));
		rev = FreeVerb.ar(sig, 1.0, 1.0, 0.7, 1.0);
		Out.ar(out, rev)
	}).add;

	SynthDef(\delay, {
		arg in, out;
		var sig, del;
		sig = In.ar(in, 2);
		sig = sig - OnePole.ar(sig, exp(-2pi * (120 * SampleDur.ir)));
		sig = OnePole.ar(sig, exp(-2pi * (14000 * SampleDur.ir)));
		del = CombN.ar(
			sig,
			4.0,
			LFNoise1.kr(0.1, 0.5, 1.5) * 2.5, //deltime between 1 and 2.5
			LFNoise1.kr(0.1, 0.5, 0.5) * 8//max 8 sec decayTime
		)!8;
		del = Splay.ar(del);
		Out.ar(out, del)
	}).add;

	SynthDef(\BPF, {
		arg freq=9000, rq=1, amp=1, gain=1.5, gate=1, jit=0.1,
		in, out, mix;
		var env, jitter, wet, dry, sig;
		dry = In.ar(in, 2);
		jitter = LFNoise2.kr(
			LFNoise2.kr(0.5, 1.5).unipolar, freq.sqrt) * jit;
		env = EnvGen.ar(Env.asr(), gate, doneAction:2);
		wet = BPF.ar(dry, (freq+jitter).abs, rq, rq.reciprocal.sqrt) * gain;
		sig = XFade2.ar(dry, wet, mix) * amp;
		Out.ar(out, sig)
	}).add;

	SynthDef.new(\textMix, {
		arg in=0, out=0, vol;
		var sig;
		sig = In.ar(in, 2) * vol;
		Out.ar(out, sig);
	}).add;

	SynthDef.new(\bufMix, {
		arg in=0, out=0, vol;
		var sig, comp;
		sig = In.ar(in, 2) * vol;
		comp = Compander.ar(sig, sig,
			thresh: 0.4,
			slopeBelow: 1,
			slopeAbove: 1/6,
			clampTime:  0.01,
			relaxTime:  0.03
		);
		sig = XFade2.ar(sig, comp, -0.5, 1);
		Out.ar(out, sig);
	}).add;

	SynthDef.new(\scapeMix, {
		arg in=0, out=0, vol;
		var sig;
		sig = In.ar(in, 2) * vol;
		Out.ar(out, sig);
	}).add;

	SynthDef(\master, {
		arg in = 0, out = 0, vol = 1;
		var sig;
		sig = In.ar(in, 2);
		sig = sig - OnePole.ar(sig, exp(-2pi * (44 * SampleDur.ir)));
		sig = sig * vol;
		sig = LeakDC.ar(sig);
		sig = Limiter.ar(sig);
		Out.ar(out, sig);
	}).add;

	s.sync;
	ServerTree.add(~makeNodes);
	s.sync;
	s.freeAll;

	[~times_1, ~stops_1].flop.do { |pair|
		~texture_1.value(pair[0], pair[1]);
	};
	[~times_2, ~stops_2].flop.do { |pair|
		~texture_2.value(pair[0], pair[1]);
	};
	[~times_3, ~stops_3].flop.do { |pair|
		~texture_3.value(pair[0], pair[1]);
	};
	[~atimes, ~astops].flop.do { |pair|
		~angryTexture.value(pair[0], pair[1])
	};
	[~stimes, ~sstops].flop.do {|pair|
		~scapes.value(pair[0], pair[1]);
	};
	[~btimes, ~bstops].flop.do {|pair|
		~rhythm.value(pair[0], pair[1]);
	};

	~chrono.value
});//waitForBoot ends

[~times_1, ~stops_1].flop.postln;
[~times_2, ~stops_1].flop.postln;
[~times_3, ~stops_1].flop.postln;
[~atimes, ~bstops].flop.postln;
[~btimes, ~bstops].flop.postln;
[~stimes, ~sstops].flop.postln;
)

var dict = {
	word: { user:"%s", 
			undefined:
				{verbose:"%s", user:"%s", cql:"%s"},			
			all_wf:
			 {label:"alle Wortformen", verbose:"alle Wortformen von: %s", user:"%s", cql:"%s"},
			lemma:
			 {label:"Lemma", verbose:"alle Wortformen von Lemma: %s", user:"%%%s", cql:"%%%s"},
			only_this_wf: 
			 {label:"nur diese Wortform", verbose:"nur Wortform: %s", user:"@%s", cql:"@%s"},
			w_start: 
			 {label:"Wortanfang", verbose:"Worte mit %s am Anfang", user:"%s*", cql:"%s*"},
			w_end: 
			 {label:"Wortende", verbose:"Worte mit %s am Ende", user:"*%s", cql:"*%s"},
			w_part: 
			 {label:"Wortteil", verbose:"Worte mit %s darin ", user:"*%s*", cql:"*%s*"},
			pattern: 
			 {label:"Muster", verbose:"Worte die Muster %s entsprechen", user:"/%s/", cql:"/%s/"}
		},
	conn: {
			seq:  
			 {label:"Sequenz", verbose:'Sequenz: "%s, %s"', user:'"%s %s"', cql:'"%s %s"'},
			hdist:  
			 {label:"Abstand", verbose:"max. %s Worte dazwischen ", user:" #%s", cql:' #%s '},
			groupor:  
			 {label:"eines von den Worten", verbose:"{    %s <br/>ODER %s }", user:"(%s | %s)", cql:"%s || %s"},			 
			groupand:  
			 {label:"alle Worte", verbose:"{ %s UND %s }", user:"(%s + %s)", cql:"(%s && %s)"},
			groupandnot:  
			 {label:"und nicht Worte", verbose:"{ %s UND NICHT %s }", user:"(%s +! %s)", cql:"(%s && !%s)"}
			},
	pos: { verbose:"Wortart: %s", user:"[%s]", cql: "$p=%s",
		pos_Nomen:
			 {user: "Nomen", verbose:"normale Nomen und Eigennamen",  cql:"/N./"},
		pos_Adj:
		 	{user: "Adjektiv", verbose:"Adjektiv", cql:"/ADJ./"},		
		pos_Pron:
		 	{user: "Pronomen", verbose:"Pronomen", cql:"/P[DIPRV]/"},		
		 pos_Verb:
		 {user: "Verb", verbose:"Verb",  cql:"/V.*/"},		 
		pos_ADJA:
		 {verbose:"attributives Adjektiv", cql:"ADJA",  user: "ADJA", example:"[das] große [Haus]"},
		pos_ADJD:
		 {verbose:"adverbiales oder prädikatives Adjektiv", cql:"ADJD",  user: "ADJD", example:"[er fährt] schnell, [er ist] schnell"},
		pos_ADV:
		 {verbose:"Adverb", cql:"ADV", user: "ADV", example:"schon, bald, doch"},
		pos_APPR:
		 {verbose:"Präposition; Zirkumposition links", cql:"APPR",  user: "APPR", example:"in [der Stadt], ohne [mich]"},
		pos_APPRART:
		 {verbose:"Präposition mit Artikel", cql:"APPRART",  user: "APPRART", example:"im [Haus], zur [Sache]"},
		pos_APPO:
		 {verbose:"Postposition", cql:"APPO",  user: "APPO", example:"[ihm] zufolge, [der Sache] wegen"},
		pos_APZR:
		 {verbose:"Zirkumposition rechts", cql:"APZR",  user: "APZR", example:"[von jetzt] an"},
		pos_ART:
		 {verbose:"bestimmter oder unbestimmter Artikel", cql:"ART",  user: "ART", example:"der, die, das, ein, eine, ..."},
		pos_CARD:
		 {verbose:"Kardinalzahl", cql:"CARD",  user: "CARD", example:"zwei [Männer], [im Jahre] 1994"},
		pos_FM:
		 {verbose:"Fremdsprachliches Material", cql:"FM",  user: "FM", example:"[Er hat das mit ``] A big fish ['' übersetzt]"},		
		pos_ITJ:
		 {verbose:"Interjektion", cql:"ITJ",  user: "ITJ", example:"mhm, ach, tja"},
		pos_ORD:
		 {verbose:"Ordinalzahl", cql:"ORD",  user: "ORD", example:"[der] neunte [August]"},
		pos_KOUI:
		 {verbose:"unterordnende Konjunktion mit 'zu' und Infinitiv", cql:"KOUI",  user: "KOUI", example:"um [zu leben], anstatt [zu fragen]"},
		pos_KOUS:
		 {verbose:"unterordnende Konjunktion mit Satz", cql:"KOUS",  user: "KOUS", example:"weil, daß, damit, wenn, ob"},
		pos_KON:
		 {verbose:"nebenordnende Konjunktion", cql:"KON",  user: "KON", example:"und, oder, aber"},
		pos_KOKOM:
		 {verbose:"Vergleichskonjunktion", cql:"KOKOM",  user: "KOKOM", example:"als, wie"},
		pos_NN:
		 {verbose:"normales Nomen", cql:"NN",  user: "NN", example:"Tisch, Herr, [das] Reisen"},
		pos_NE:
		 {verbose:"Eigennamen", cql:"NE",  user: "NE", example:"Hans, Hamburg, HSV"},
		pos_PDS:
		 {verbose:"substituierendes Demonstrativpronomen", cql:"PDS",  user: "PDS", example:"dieser, jener"},
		pos_PDAT:
		 {verbose:"attribuierendes Demonstrativpronomen", cql:"PDAT",  user: "PDAT", example:"jener [Mensch]"},
		pos_PIS:
		 {verbose:"substituierendes Indefinitpronomen", cql:"PIS",  user: "PIS", example:"keiner, viele, man, niemand"},
		pos_PIAT:
		 {verbose:"attribuierendes Indefinitpronomen ohne Determiner", cql:"PIAT",  user: "PIAT", example:"kein [Mensch], irgendein [Glas]"},
		pos_PIDAT:
		 {verbose:"attribuierendes Indefinitpronomen mit Determiner", cql:"PIDAT",  user: "PIDAT", example:"[ein] wenig [Wasser], [die] beiden [Brüder]"},
		pos_PPER:
		 {verbose:"irreflexives Personalpronomen", cql:"PPER",  user: "PPER", example:"ich, er, ihm, mich, dir"},
		pos_PPOSS:
		 {verbose:"substituierendes Possessivpronomen", cql:"PPOSS",  user: "PPOSS", example:"meins, deiner"},		
		pos_PPOSAT:
		 {verbose:"attribuierendes Possessivpronomen", cql:"PPOSAT",  user: "PPOSAT", example:"mein [Buch], deine [Mutter]"},		
		pos_PRELS:
		 {verbose:"substituierendes Relativpronomen", cql:"PRELS",  user: "PRELS", example:"[der Hund ,] der"},
		pos_PRELAT:
		 {verbose:"attribuierendes Relativpronomen", cql:"PRELAT",  user: "PRELAT", example:"[der Mann ,] dessen [Hund]"},
		pos_PRF:
		 {verbose:"reflexives Personalpronomen", cql:"PRF",  user: "PRF", example:"sich, einander, dich, mir"},
		pos_PWS:
		 {verbose:"substituierendes Interrogativpronomen", cql:"PWS",  user: "PWS", example:"wer, was"},
		pos_PWAT:
		 {verbose:"attribuierendes Interrogativpronomen", cql:"PWAT",  user: "PWAT", example:"welche [Farbe], wessen [Hut]"},
		pos_PWAV:
		 {verbose:"adverbiales Interrogativ- oder Relativpronomen", cql:"PWAV",  user: "PWAV", example:"warum, wo, wann, worüber, wobei"},
		pos_PAV:
		 {verbose:"Pronominaladverb", cql:"PAV",  user: "PAV", example:"dafür, dabei, deswegen, trotzdem"},
		pos_PTKZU:
		 {verbose:"'zu' vor Infinitiv", cql:"PTKZU",  user: "PTKZU", example:"zu [gehen]"},
		pos_PTKNEG:
		 {verbose:"Negationspartikel", cql:"PTKNEG",  user: "PTKNEG", example:"nicht"},
		pos_PTKVZ:
		 {verbose:"abgetrennter Verbzusatz", cql:"PTKVZ",  user: "PTKVZ", example:"[er kommt] an, [er fährt] rad"},
		pos_PTKANT:
		 {verbose:"Antwortpartikel", cql:"PTKANT",  user: "PTKANT", example:"ja, nein, danke, bitte"},
		pos_PTKA:
		 {verbose:"Partikel bei Adjektiv oder Adverb", cql:"PTKA",  user: "PTKA", example:"am [schönsten], zu [schnell]"},
		pos_SPELL:
		 {verbose:"Buchstabierfolge", cql:"SPELL",  user: "SPELL", example:"S-C-H-W-E-I-K-L"},
		pos_TRUNC:
		 {verbose:"Kompositions-Erstglied", cql:"TRUNC",  user: "TRUNC", example:"An- [und Abreise]"},
		pos_VVFIN:
		 {verbose:"finites Verb, voll", cql:"VVFIN",  user: "VVFIN", example:"[du] gehst, [wir] kommen [an]"},
		pos_VVIMP:
		 {verbose:"Imperativ, voll", cql:"VVIMP",  user: "VVIMP", example:"komm [!]"},
		pos_VVINF:
		 {verbose:"Infinitiv, voll", cql:"VVINF",  user: "VVINF", example:"gehen, ankommen"},
		pos_VVIZU:
		 {verbose:"Infinitiv mit ``zu'', voll", cql:"VVIZU",  user: "VVIZU", example:"anzukommen, loszulassen"},
		pos_VVPP:
		 {verbose:"Partizip Perfekt, voll", cql:"VVPP",  user: "VVPP", example:"gegangen, angekommen"},
		pos_VAFIN:
		 {verbose:"finites Verb, aux", cql:"VAFIN",  user: "VAFIN", example:"[du] bist, [wir] werden"},
		pos_VAIMP:
		 {verbose:"Imperativ, aux", cql:"VAIMP",  user: "VAIMP", example:"sei [ruhig !]"},
		pos_VAINF:
		 {verbose:"Infinitiv, aux", cql:"VAINF",  user: "VAINF", example:"werden, sein"},
		pos_VAPP:
		 {verbose:"Partizip Perfekt, aux", cql:"VAPP",  user: "VAPP", example:"gewesen"},
		pos_VMFIN:
		 {verbose:"finites Verb, modal", cql:"VMFIN",  user: "VMFIN", example:"dürfen"},
		pos_VMINF:
		 {verbose:"Infinitiv, modal", cql:"VMINF",  user: "VMINF", example:"wollen"},
		pos_VMPP:
		 {verbose:"Partizip Perfekt, modal", cql:"VMPP",  user: "VMPP", example:"gekonnt, [er hat gehen] können"},
		pos_XY:
		 {verbose:"Nichtwort, Sonderzeichen enthaltend", cql:"XY",  user: "Nichtwort", example:"3:7, H2O, D2XW3"},
		pos_c:
		 {verbose:"Komma", cql:"\$,",  user: "Komma", example:","},
		pos_sent_end:
		 {verbose:"Satzbeendende Interpunktion", cql:"\$.",  user: "Satzende", example:". ? ! ; :"},
		pos_interp:
		 {verbose:"sonstige Satzzeichen; satzintern", cql:"\$(",  user: "Satzzeichen", example:"- [,]()"}
	},
				
	test: ['Haus', 
'@Häuser', 
'%Blume', 
'Ha*', 
'*us', 
'*au*', 
'/uo.*/', 
'"schönes Haus"', 
'[NE]', 
'[Pronomen]', 
'"[ADJA] [Nomen]"', 
'"große [ADJA] Liebe"', 
'das oder der', 
'das | der', 
'(der oder das oder etwas)', 
'(schön und groß und etwas)', 
'"süss #6 krank"', 
'"Ma*[NN] vor*"', 
'sehr und ("schön [NN]" oder "krank [VVFIN]")', 
'("asdf adsfölkj" or "mnb (a | b)") and ("asdf adsfölkj" or "mnb poi")', 
'(asdf or sdf and wer)', 
'/Ha.*s/ || (dem && Leben)', 
'("asdf adsfölkj" or "asdflkj [NE]")', 
'("sdflkj* [ADJD] [ADJA]" or la)']
};
 
 
 
function resolveUserToken(type, token, mode) {
	var res="";

	var dict_part = dict[type];
	// output(token);
	for (entry in dict_part) {				
		var key = entry.toString();		
		if (dict_part[key]['user']==token) {			
			// output(dict_part[key]['user']);
		 return dict_part[key][mode];			
		}
	}	
	return token;
	/*
	if (dict) res = dict[type][key]['cql'];	
	if (!res) res=key;
	
	return res;
	*/
}


function resolveKey(pkey, mode) {
	var res="";

	if (!dict) return res;
	
	  //output("rK():" + pkey);
	for (part in dict) {				
		for (entry in dict[part]) {						
			//var entry_key = entry.toString();			
			if (entry ==pkey) {			
					res = dict[part][mode] ? dict[part][mode] : "%s"; 		
					res = sprintf(res, dict[part][entry][mode]); //wrap type-prefix/sufix, especially for POS			
					return res;
			}					
		}
	}	
	return res;
	
}

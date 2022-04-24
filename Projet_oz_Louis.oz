declare
local
    % See project statement for API details.
    % !!! Please remove CWD identifier when submitting your project !!!
    %CWD = 'C:/Users/PC/OneDrive/Documents/Mes études/Master/Q2/LINFO1104 Concepts des langages de programmation/Projet_oz/project_template/' % Put here the **absolute** path to the project files
    [Project] = {Link [CWD#'Project2022.ozf']}
    Time = {Link ['x-oz://boot/Time']}.1.getReferenceTime
 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        







    
    fun {NoteToExtended Note}
       case Note
       of Name#Octave then
          note(name:Name octave:Octave sharp:true duration:1.0 instrument:none)
       [] Atom then
          case {AtomToString Atom}
          of [_] then
             note(name:Atom octave:4 sharp:false duration:1.0 instrument:none)
          [] [N O] then
             note(name:{StringToAtom [N]}
                  octave:{StringToInt [O]}
                  sharp:false
                  duration:1.0
                  instrument: none)
          end
       end
    end
 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

    fun {Stretch Factor Part}    %ok ça marche
        local Fact in
            Fact={PartitionToTimedList Part}
            local  
                fun {StretchExtention LaPart}
                    case LaPart of H|T then
                        case H of stretch(factor:LeFactor P) then
                            {Append {Stretch LeFactor P} {StretchExtention T}}
                        [] duration(seconds:Seconds P) then
                            {Append {Duration Seconds P} {StretchExtention T}}
                        [] drone(note:Note amount:Amount) then
                            {Append {Drone Note Amount} {StretchExtention T}}
                        [] transpose(semitones:Semitones P) then
                            {Append {Transpose Semitones P} {StretchExtention T}} 
                        []  D|F then
                            if {HasFeature D name} then
                                (note(name:D.name octave:D.octave sharp:D.sharp duration:D.duration*Factor instrument:D.instrument)|{StretchExtention F})|{StretchExtention T}
                            else
                            (silence(duration:D.duration*Factor)|{StretchExtention F})|{StretchExtention T}
                            end
                        else
                            if {HasFeature H name} then
                                note(name:H.name octave:H.octave sharp:H.sharp duration:H.duration*Factor instrument:H.instrument)|{StretchExtention T}
                            else
                                silence(duration:H.duration*Factor)|{StretchExtention T}
                            end
                        end
                    [] nil then nil
                    end
                end
            in
                {StretchExtention Fact}
            end
        end
    end 
    
    



    fun {ToNumNote TheNote}
        case TheNote.name of 'a' then 
            if TheNote.sharp then 11+ 12*(TheNote.octave -1)  
            else  10+ 12*(TheNote.octave -1 ) 
            end
        [] 'b' then
            12 + 12*(TheNote.octave -1 )
        [] 'c' then
            if TheNote.sharp then 2+ 12*(TheNote.octave -1) 
            else 1 + 12*(TheNote.octave -1 )
            end
        [] 'd' then
            if TheNote.sharp then 4+ 12*(TheNote.octave -1)  
            else  3+ 12*(TheNote.octave -1 ) 
            end
        [] 'e' then
            5  +12*(TheNote.octave -1 )
        [] 'f' then
            if TheNote.sharp then 7+ 12*(TheNote.octave -1)  
            else 6 + 12*(TheNote.octave -1 ) 
            end
        [] 'g' then
            if TheNote.sharp then 9+ 12*(TheNote.octave -1) 
            else  8 + 12*(TheNote.octave -1 ) 
            end
        end
    end


    fun {ToNote I} %problème, duration=1 je veux duration=duration
        local NameNote Octave NumNote SharpTrue in
            fun{SharpTrue Diese}
                case Diese of 2 then true
                [] 4 then true
                [] 7 then true
                [] 9 then true
                [] 11 then true
                else false end
            end
            Octave = (I div 12)+1
            NumNote = I mod 12 
            NameNote = name(0:b 1:c 2:c 3:d 4:d 5:e 6:f 7:f 8:g 9:g 10:a 11:a)
            note(name:NameNote.NumNote duration:1.0 octave:Octave sharp:{SharpTrue NumNote} instrument:none)
        end
    end

    fun{Transpose Semiton Part} %Juste un problème avec duration (pas la fonction)
        local Iterate in
            fun{Iterate Tail}
                case Tail of H|T then
                    case H of silence(duration:A) then silence(duration:A)|{Iterate T}
                    []D|F then {Transpose Semiton D}|{Iterate T}
                    else {ToNote {ToNumNote H}+Semiton}|{Iterate T} 
                    end
                []nil then nil
                end 
            end 
            {Iterate {PartitionToTimedList Part}}
        end 
    end



    fun{DurationPart Partition}
        case Partition of D|F then
            case D of stretch(factor:Factor P) then
                {DurationPart {Append {Stretch Factor P} F}}
            [] drone(note:Note amount:P) then
                {DurationPart {Append {Drone Note P} F}}
            [] duration(seconds:Seconds P) then
                {DurationPart {Append {Duration Seconds P} F}}
            [] transpose(semitones:Semitones P) then            
                {DurationPart {Append {Transpose Semitones P} F}}
            [] H|T then
                if {HasFeature H duration} then H.duration+{DurationPart F}
                else
                    1.0+{DurationPart F}
                end
            [] Name#Octave then 1.0+{DurationPart F}
            [] Atom then
                if {HasFeature D duration} then D.duration+{DurationPart F}
                else
                    1.0+{DurationPart F}
                end
            end
        [] nil then 0.0
        else
            1.0
        end
    end


    fun{Duration Seconds Partition}  %marche mais bizarement pas avec tous les tests mais je sais pas pq...
        local Time Factor in
	        Time={DurationPart Partition}
	        Factor=Seconds/Time
	        {Stretch Factor Partition}
        end
    end



    fun{Drone Note Amount} %ok drone marche parfaitement
        if Amount==0 then nil
        else
            case {Flatten Note} of [_] then {Flatten Note|{Drone Note Amount-1}}
            else Note|{Drone Note Amount-1}
            end
        end
    end


    

    fun {PartitionToTimedList Partition}
        case Partition of D|F then
            case D of duration(seconds:Seconds P) then
                {Append {PartitionToTimedList {Duration Seconds P}} {PartitionToTimedList F}}
            [] stretch(factor:Factor P) then
                {Append {Stretch Factor P} {PartitionToTimedList F}}
            [] drone(note:Note amount:P) then
               {Append {Drone Note P} {PartitionToTimedList F}}
            [] transpose(semitones:Semitones P) then
               {Append {Transpose Semitones P} {PartitionToTimedList F}}
            [] H|T then
                if {HasFeature H duration} then D|{PartitionToTimedList F}
                else
                  ({NoteToExtended H}|{PartitionToTimedList T})|{PartitionToTimedList F}
                end
            [] Name#Octave then {NoteToExtended D}|{PartitionToTimedList F}
            [] Atom then
                if {HasFeature D duration} then D|{PartitionToTimedList F}
                else
                    {NoteToExtended D}|{PartitionToTimedList F}
                end
            else
               {PartitionToTimedList F}
            end
        else nil
        end
        
    end
   

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Music = {Project.load 'example.dj.oz'}
    Start
 
in
    Start = {Time}
 
   
    {ForAll [NoteToExtended Music] Wait}
  
    {Browse {Project.run Mix PartitionToTimedList Music 'out.wav'}}
    
    {Browse {IntToFloat {Time}-Start} / 1000.0}
 
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                            %Fonction Mix%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
declare %ok ça marche
fun{Reverse Music}
    {List.reverse Music}
end
{Browse {Reverse [1.0 2.0 3.0]}}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

declare %ça, ça marche
fun{Repeat Natural Music}
   fun{Repeat Natural Music Acc}
      if Natural == 0 then Acc
      else {Repeat Natural-1 Music Music|Acc}
      end
   end
in
   {Repeat Natural Music nil}
end

declare
Music = [1.0 2.0 3.0]
{Browse {Repeat 3 Music}}




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

declare %ça marche, attention au argument Start=0.0001 pour avoir la première valeur de la liste
fun{Cut Start Finish Music}
    local  MaFun Stop1 Start1   in
        Stop1 = {Float.toInt Finish*44100.0}
        Start1 = {Float.toInt Start*44100.0}
        fun{MaFun Nbr Music1}
            if Nbr =< Stop1 then
                case Music1
                of nil then
                    0.0|{MaFun Nbr+1 nil}
                [] H|T then
                    if Nbr<Start1 then
                        {MaFun Nbr+1 T}
                    else
                        H|{MaFun Nbr+1 T}
                    end
                end
        
            else
                nil
        
            end
    
        end
        {MaFun 1 Music}
    end
end
%{Browse {Cut 0.00012 0.00034 [1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 ]}}



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

declare
fun{Loop Duration Musique}
    fun{Loop1 Duration1 Musique1 Accumulateur}
        if Duration1==0 then Accumulateur
        else case Musique1 of nil then
	        {Loop1 Duration1 Musique Accumulateur}
	        [] H|T then
	            {Loop1 Duration1-1 T H|Accumulateur}
	        end
        end
    end
in
   {Reverse {Loop1 {FloatToInt 44100.0*Duration} Musique nil}}
end

declare
Duration=0.0004
Musique=[1 2 3 4 5 6 7 8 9]
{Browse {Loop Duration Musique}}



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
declare %ok ça marche
fun{Clip Low High Music}
   if Low>=High then nil
   else
      case Music
      of nil then nil
      [] H|T then
	        if H>High then High|{Clip Low High T}
	        elseif (H=<High andthen H>=Low) then H|{Clip Low High T}
	        else Low|{Clip Low High T}
	        end
        end
    end
end

declare
{Browse {Clip 1.0 3.0 [1.0 2.2 3.0 ~1.0 4.3]}}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


declare
fun {Echo Delay Decay Music} %Besoin de merge pour tester cette fonction
    merge([1.0#M Decay#(silence(duration:Delay)|Music)])
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

declare %ça marche
fun{Fade Start Out Music}
    local Start1 Out1 Fade1 FadeD FadeT FadeF in
        Out1 = {Float.toInt Out*44100.0}
        Start1 = {Float.toInt Start*44100.0}
        fun{Fade1 I Music1 Out2}
            case Music1
            of nil then nil
            [] H|T then
                if I=<Out2 then
                    (H*{Int.toFloat I})/{Int.toFloat Out2}|{Fade1 I+1 T Out2}
                else
                    H|{Fade1 I+1 T Out2}
    
                end
            end
        end
        FadeD = {Fade1 1 Music Start1}
        FadeT = {Reverse FadeD}
        FadeF = {Fade1 1 FadeT Out1}
        {Reverse FadeF}

    end
end
{Browse {Fade 0.0002 0.0002 [1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0]}}



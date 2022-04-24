%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%									%%%%%
%%%%%                  LINFO1104 Projet 2022 - MaestrOz		        %%%%%
%%%%%                  Thibault Decoene - 29291800			%%%%%
%%%%%                  Louis Parys - 72561700				%%%%%
%%%%%									%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

local
   % See project statement for API details.
   % !!! Please remove CWD identifier when submitting your project !!!
   CWD = '/Users/user/Documents/Q2/LINFO1104/Project/project_template' % Put here the **absolute** path to the project files
   [Project] = {Link [CWD#'Project2022.ozf']}
   Time = {Link ['x-oz://boot/Time']}.1.getReferenceTime

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %                       1. PartitionToTimedList                             %
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
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
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

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    fun{Duration Seconds Partition}  %marche mais bizarement pas avec tous les tests mais je sais pas pq...
        local Time Factor in
	        Time={DurationPart Partition}
	        Factor=Seconds/Time
	        {Stretch Factor Partition}
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    fun{Drone Note Amount} %ok drone marche parfaitement
        if Amount==0 then nil
        else
            case {Flatten Note} of [_] then {Flatten Note|{Drone Note Amount-1}}
            else Note|{Drone Note Amount-1}
            end
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
   

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %                                2. Mix                                     %
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   % Donne la position relative d'une note au La de la même octave 
   % In : Note au format note(name:N octave:O sharp:S duration:D instrument:I)
   % Out : Integer correspondant à la position

   declare 
   fun{Position Note}
      local Y in 
         if Note.sharp == false then 
            case Note.name
            of c then Y=~9
            [] d then Y=~7
            [] e then Y=~5   % Pas de sharp donc -1 pour f
            [] f then Y=~4
            [] g then Y=~2
            [] a then Y=0
            [] b then Y=2
            end
         else                % e et b sharp n'existe pas
            case Note.name
            of c then Y=~8
            [] d then Y=~6
            [] f then Y=~3
            [] g then Y=~1
            [] a then Y=1
            end
         end
      end
   end

   declare
   Y = note(name:g octave:3 sharp:true duration:1 instrument:none)
   {Browse{Position Y}}

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % Donne la position absolue d'une note par rapport au La de référence (hauteur)
   % In : Note au format note(name:N octave:O sharp:S duration:D instrument:I)
   % Out : Float correspondant à la position absolue
   
   declare 
   fun{Hauteur Note}
     (Note.octave-4.0)*12.0+{IntToFloat{Position Note}}
   end 

   declare
   Y = note(name:g octave:3.0 sharp:true duration:1.0 instrument:none)
   {Browse{Hauteur Y}}

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   % Donne la fréquence si note et 0 si silence ou autre
   % In : Note au format note(name:N octave:O sharp:S duration:D instrument:I)
   % Out : Float correspondant à la fréquence

   declare 
   fun{Frequence Note} 
      case Note 
      of silence(duration:D) then 0.0
      [] note(name:N octave:O sharp:S duration:D instrument:I) then
         {Pow 2.0 {Hauteur Note}/12.0}*440.0 % QUESTION : ok de mettre une fonction dans une formule ? 
      end
   end
   
   declare
   Y = note(name:g octave:3.0 sharp:true duration:1.0 instrument:none) 
   X = silence(duration:1.0)
   {Browse{Frequence Y}} 
   {Browse{Frequence X}}
 
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % Donne une liste d'échantillon sur base d'une note
   % In : Note au format note(name:N octave:O sharp:S duration:D instrument:I)
   % Out : liste d'échantillons float

   declare
   fun {Note_Echantillon Note} 
      fun{Echantillon Note Acc}
         if Acc =< {FloatToInt Note.duration * 44100.0} then  
            0.5 * ({Sin ((2.0 * 3.141592 * {Frequence Note} * {IntToFloat Acc})/44100.0)}) | {Echantillon Note Acc+1}
         else 
            nil 
         end 
      end 
   in
      {Echantillon Note 1} 
   end 

   declare
   Y = note(name:g octave:3.0 sharp:true duration:1.0 instrument:none)
   {Browse{Note_Echantillon Y}} 

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   % Fonction d'addition de deux listes
   % In : 2 listes
   % Out : 1 listes composées des deux listes initiales

   declare
   fun{Sum X Y} 
      case X 
      of A|B then 
         case Y 
         of C|D then A+C | {Sum B D} 
         [] nil then A | {Sum B nil} 
         end 
      [] nil then
         case Y 
         of C|D then C | {Sum nil D}
         [] nil then nil 
         end
      end 
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   % Donne une liste d'échantillon pour chaque note d'un accord
   % In : un accord
   % Out : une liste d'échantillon 

   declare 
   fun{Accord_Echantillon Accord}
	   case Accord 
	   of H|T then {Sum {Note_Echantillon H} {Accord_Echantillon T}} 
	   [] H|nil then {Note_Echantillon H}    
	   end
	end 

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % Échantillonne la partition
   % In : une partition
   % Out : liste d'échantillons

   declare
   fun{Partition Part}
      case  Part
      of H|T then 
         case H 
         of note(name:N octave:O sharp:S duration:D instrument:I) then
            {Note_Echantillon H}|{Partition T}
         else 
            {Accord_Echantillon H} | {Partition T}
         end
      [] nil then 
         nil 
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   % Wav file

   fun{Wave Name}
      {Project.Load Name}
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % Fonction Multiplication
   declare
   fun{Multi A B} 
      case A 
      of H|T then 
         B*H|{Multi T B}
      else nil
      end
   end 

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % Addition membre à membre des listes et multiplication par l'intensité
   
   fun{Merge W Yolo} 
      case W 
      of H|T then
         case H
         of I#Music then
            local
               Sample = {Mix Yolo Music}
               Intensite = {Multi Sample I} 
            in
               {Sum Intensite {Merge T Yolo}}
            end
      [] nil then 
         nil 
         end
      end
   end
   
	
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

declare %renvoie 0|0|0|0|0|0|0|0|0|0|0|0|,,, je ne sais pas pq...
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
{Browse {Cut 4.0 9.0 [1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 ]}}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

declare %ne renvoie rien vu que j'utilise cut qui ne marche pas
fun {Loop Duration Music}
    local  NbrSample LongueurMusic in
       NbrSample = {FloatToInt Duration*44100.0}   
       LongueurMusic = {List.length Music}     
       {Append {Repeat (NbrSample div LongueurMusic) Music} {Cut 0 (NbrSample mod LongueurMusic) Music}}
    end
 end


 {Browse {Loop 16.0 [1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 ]}}

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

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   fun {Mix P2T Music} % Structure à modifer
      case Music of H|T then
         case H 
         of samples(P) then
            {Append P {Mix P2T T}}
         [] partition(P) then 
            {Append {Partition P} {Mix P2T T}}
         [] wave(P) then
            {Append {Wave P} {Mix P2T T}}
         [] merge(P) then 
            {Append {Merge P A} {Mix P2T T}}
         [] reverse(P) then
            {Append {Reverse P} {Mix P2T T}}
         [] repeat(amount:A P) then
            {Append {Repeat A P} {Mix P2T T}}
         [] loop(duration:A P) then
            {Append {Loop A P} {Mix P2T T}}
         [] clip(low:A high:B P) then
            {Append {Clip A B P} {Mix P2T T}}
         [] echo(delay:T decay:A P) then
            {Append {Echo T A P} {Mix P2T T}}
         [] fade(start:A out:B P) then
            {Append {Fade A B P} {Mix P2T T}}
         [] cut(start:A finish:B P) then
            {Append {Cut A B P} {Mix P2T T}}
         else
            nil
         end
      else
         nil
      end 
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   Music = {Project.load CWD#'joy.dj.oz'}
   Start

   % Uncomment next line to insert your tests.
   % \insert '/full/absolute/path/to/your/tests.oz'
   % !!! Remove this before submitting.
in
   Start = {Time}

   % Uncomment next line to run your tests.
   % {Test Mix PartitionToTimedList}

   % Add variables to this list to avoid "local variable used only once"
   % warnings.
   {ForAll [NoteToExtended Music] Wait}
   
   % Calls your code, prints the result and outputs the result to `out.wav`.
   % You don't need to modify this.
   {Browse {Project.run Mix PartitionToTimedList Music 'out.wav'}}
   
   % Shows the total time to run your code.
   {Browse {IntToFloat {Time}-Start} / 1000.0}
end
  

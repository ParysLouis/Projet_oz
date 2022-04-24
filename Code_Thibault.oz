%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% LINFO1104 Projet 2022 - MaestrOz
% Thibault Decoene - 29291800
% Louis Parys - NOMA

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

   % Voir partie de Louis  

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
  
     
    

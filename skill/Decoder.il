/*====================================================================

 This file defines the SKILL procedure for creating 
   SCHEMATIC of a N-bit Decoder with SCL180 technology.

=====================================================================*/

;; Load the file containing the basic schematic procedures
load("./skill/Schematic.il")


/*====================================================================
 Define the procedure for creating schematic of the N-bit Decoder
   chain.
 This procedure has 3 parameter:
 - libName: the name of the library that you will put the cell schematic in;
 - cellName: the name of the cell you will create;
 - N: the number of data bits of the Decoder
=====================================================================*/
procedure(DecoderSchematic(libName cellName N LOG2N)

  ;; Define the local variables
  prog((cvid x y pin pinName k h temp inName outName0 outName1 config config_ inst)
  
    ;; Open the cell and its schematic view
    cvid = dbOpenCellViewByType(libName cellName "schematic" "schematic" "a")
	
	;; Clean the schematic view
    ece432DeleteObjectsSchematic(cvid)
	
	;; The coordinate of the origin point for the schematic
    x=0
    y=0
	
    ;; Create top level pins
	
	;; Create input pins
	for(u 1 LOG2N
		config=sprintf(nil "config%L" u)
		config_=sprintf(nil "config_%L" u)
		pin=ece432SchematicCreatePin(cvid config "input" x:y "R0")
      	y=y+0.5
		pin=ece432SchematicCreatePin(cvid config_ "input" x:y "R0")
      	y=y+0.5
    );; end for(u

	;; Create output pins
	for(q 1 N
		outName0=sprintf(nil "OUT_%L" 2*q-1)
		outName1=sprintf(nil "OUT_%L" 2*q)	
		pin=ece432SchematicCreatePin(cvid outName0 "output" x:y "R0")
      	y=y+0.5
		pin=ece432SchematicCreatePin(cvid outName1 "output" x:y "R0")
      	y=y+0.5
    );; end for(q

	;; Create inout pins
    foreach(pinName list("vdd" "gnd")
      pin=ece432SchematicCreatePin(cvid pinName "inputOutput" x:y "R0")
      y=y+0.5
    )
	;; The coordinate of the origin point for the schematic
    x=1
    y=0
	
	;; Create the decoder using tx-gates
	temp=1
	for(h 1 LOG2N
		for(k 1 temp
	
		  ;; Define the input and output net name of the first inverter
		  if(h==1 then
			inName="vdd"
			outName0="out0_1_1"
			outName1="out1_1_1" 
		  else
			if(mod(k 2)==1 then
			  inName=sprintf(nil "out0_%L_%L" h-1 (k+1)/2)
			else
			  inName=sprintf(nil "out1_%L_%L" h-1 k/2)
			);;end if(k%2==1
			if(h==LOG2N then
		      outName0=sprintf(nil "OUT_%L" 2*k-1)
			  outName1=sprintf(nil "OUT_%L" 2*k)		  
			else
			  outName0=sprintf(nil "out0_%L_%L" h k)
			  outName1=sprintf(nil "out1_%L_%L" h k)
            );; end if(h==LOG2N
	      );; end if(h==1
		  config=sprintf(nil "config%L" h)		
		  config_=sprintf(nil "config_%L" h)  
		  ;; Instantiate the kth tx-gate with ece432SchematicCreateInst() procedure, 
		  ;; which is defined in the file 'ece432Schematic.il'. 
		  ;; This procedure needs 10 paramters
		  inst = ece432SchematicCreateInst(
			       ;; Cell view id
				   cvid 
				   
				   ;; Name of the library containing the inverter cell
				   libName
				   
			       ;; The tx-gate cell name  
		           "transmission_gate"  
				   
				   ;; Cell view type, always be "symbol" here
				   "symbol" 
				   
				   ;; Instance name
			       sprintf(nil "TX_%L_%L" h k) 
				   
				   ;; The following list defines the connections of the left side pins 
				   ;; in the symbol view; For our inverter, 'in' is the only pin on the left.
				   ;; The inverter pin 'in' is connected with the net 'inName'.
				   ;; If there are multiple pins on the left side, you can use the below way to define.
				   ;;    list(list("in1" in1net)
				   ;;         list("in2" in2net))
				   ;; If there is no pin on the left side, this parameter should be 'nil'.
			       list(list("in" inName))   
				   
				   ;; The following list defines the connections of the right side pins 
				   ;; in the symbol view; For our inverter, 'out' is the only pin on the right.
		  		   list(list("out0" outName0) 
				   		list("out1" outName1)) 
				   ;; The following list defines the connections of the top side pins 
				   ;; in the symbol view; For our inverter, 'VDD' is the only pin on the top.
		  		   list(list("vdd"  "vdd")
				   		list("config" config)
				   		list("config_" config_)) 

				   ;; The following list defines the connections of the bottom side pins 
				   ;; in the symbol view; For our inverter, 'VSS' is the only pin on the bottom.
			       list(list("gnd"  "gnd"))
				   
				   ;; Location of the instance
		           x:y 
				   
				   ;; Rotation of the instance, such as "R0", "R90", "R180", "R270", "MX", "MY", ...
				   "R0"
				 );; end inst =
		    
		  ;; The next tx will be put at the right side of the current one.   
		  y=y-2*N/temp
		  
		);; end for(k
	temp=temp*2
	y=N*(temp-1)/temp
	x=x+10

	);; end for(h
	;; Check, save and close the cell view
	schCheck(cvid)  ;; check the schematic connectivity
    dbSave(cvid)
    dbClose(cvid)
	
    return(t)
	
  );; end prog
  
);; end procedure



/*====================================================================
 'let' is the main entrance of the skill program.
 We will build schematic for a 6-bit inverter chain as an example.
====================================================================*/
let((N libName cellName)  ;; N, libName and cellName are variables

  ;; The number of inverters
  N = 64
  LOG2N = 7
  ;; The name of the library we will put the new cell in
  libName="sumitfpga"
  
  ;; Define the cell name as 'invChain_6b'
  sprintf(cellName "Decoder_%L_%L" N LOG2N)

  ;; Call the procedure to create the inverter chain schematic
  DecoderSchematic(libName cellName N LOG2N)

  printf("=== Cell %L Schematic has been created! ===\n", cellName)

) ;;end let
 

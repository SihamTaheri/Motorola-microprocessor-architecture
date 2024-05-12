*Inicializa el SP y el PC
**************************
        ORG     $0
        DC.L    $8000           * Pila
        DC.L    INICIO          * PC

        ORG     $400
*****************************************************************

*PROGRAMA HECHO POR LOS PARTICIPANTES DEL GRUPO 02743183
*DANIEL RODRIGUEZ
*SIHAM TAHERI
*
*****************************************************************
*Definición de equivalencias
*********************************

MR1A    EQU     $effc01       * de modo A (escritura)
MR2A    EQU     $effc01       * de modo A (2º escritura)
SRA     EQU     $effc03       * de estado A (lectura)
CSRA    EQU     $effc03       * de seleccion de reloj A (escritura)
CRA     EQU     $effc05       * de control A (escritura)
TBA     EQU     $effc07       * buffer transmision A (escritura)
RBA     EQU     $effc07       * buffer recepcion A  (lectura)
ACR	EQU	$effc09	      * de control auxiliar
IMR     EQU     $effc0B       * de mascara de interrupcion A (escritura)
ISR     EQU     $effc0B       * de estado de interrupcion A (lectura)
MR1B    EQU     $effc11       * de modo B (escritura)
MR2B    EQU     $effc11       * de modo B (2º escritura)
CRB     EQU     $effc15	      * de control A (escritura)
TBB     EQU     $effc17       * buffer transmision B (escritura)
RBB	EQU	$effc17       * buffer recepcion B (lectura)
SRB     EQU     $effc13       * de estado B (lectura)
CSRB	EQU	$effc13       * de seleccion de reloj B (escritura)
IVR	EQU	$effc19
IMR2

CR	EQU	$0D	      * Carriage Return
LF	EQU	$0A	      * Line Feed
FLAGT	EQU	2	      * Flag de transmisión
FLAGR   EQU     0	      * Flag de recepción

**************************** INIT *************************************************************
INIT:
        MOVE.B          #%00010000,CRA      * Reinicia el puntero MR1
	MOVE.B          #%00010000,CRB     
        MOVE.B          #%00000011,MR1A     * 8 bits por caracter.
	MOVE.B          #%00000011,MR1B
        MOVE.B          #%00000000,MR2A     * Eco desactivado.
        MOVE.B          #%00000000,MR2B
        MOVE.B          #%11001100,CSRA     * Velocidad = 38400 bps.
	MOVE.B          #%11001100,CSRB
        MOVE.B          #%00000000,ACR      * Velocidad = 38400 bps.

	MOVE.B          #$40,IVR
        MOVE.B          #%00000101,CRA      * Transmision y recepcion activados.
        MOVE.B          #%00000101,CRB
	MOVE.B          #%00100010,IMR     *Cambiar al de la derecha del 1 a 0
	MOVE.B		#%00100010,IMR2 
	MOVE.L		#RTI,$100
	BSR 		INI_BUFS
	MOVE.W		#$2000,SR
	RTS

**************************** FIN INIT *********************************************************

**************************** Print
 ********************************************************
PRINT:
	LINK A6,#-28

        MOVE.L D2,-4(A6)
        MOVE.L D5,-8(A6)
        MOVE.L D3,-12(A6)
        MOVE.L D4,-16(A6)
        MOVE.L D6,-20(A6)
        MOVE.L D1,-24(A6)
        MOVE.L A1,-28(A6)
        
        CLR.L D2
        CLR.L D5
        CLR.L D3
        CLR.L D4 *DESCRIPTOR
        CLR.L D6 *CONTADOR DE CARACTERES
        MOVE.L 8(A6),A1
        MOVE.W 14(A6),D2
        MOVE.W 12(A6),D4
        CMP.B #0,D4
        BNE SINO
        MOVE.L #2,D3
        ADD.L #1,D5
SINO:   CMP.L #1,D4
        BNE SINO2
        MOVE.L #3,D3
        ADD.L #1,D5
SINO2:  CMP.L #0,D5
        BNE PRINTG
        MOVE.L #$FFFFFFFF,D0
        BRA FI_PRINT

PRINTG: CLR.L D0
	CLR.L D1
	MOVE.L D3,D0
	CMP.W #0,D2
	BEQ FINAL
	MOVE.B (A1)+,D1
	BSR ESCCAR
	CMP.L #-1,D0
	BEQ FINAL
	SUB.W #1,D2
	ADD.L #1,D6
	BRA PRINTG

FINAL:  CMP.L #0,D6
        BEQ FINAL2
        CMP.L #2,D3
        BNE SINO3
        BSET #0,IMR2
SINO3:  CMP.L #3,D3
        BNE SINO4
        BSET #4,IMR2
SINO4:  MOVE.B IMR2,IMR

FINAL2: MOVE.L D6,D0

FI_PRINT: 
	  MOVE.L -28(A6),A1
          MOVE.L -24(A6),D1
          MOVE.L -20(A6),D6
          MOVE.L -16(A6),D4
          MOVE.L -12(A6),D3
          MOVE.L -8(A6),D5
          MOVE.L -4(A6),D2
          UNLK A6
          RTS
	



**************************** FIN PRINT ********************************************************

**************************** SCAN ************************************************************
SCAN:	
	LINK A6,#-16

        MOVE.L D5,-4(A6)
        MOVE.L D6,-8(A6)
        MOVE.L D3,-12(A6)
        MOVE.L A1,-16(A6)
        
	MOVE.L 8(A6),A1 *guardamos en r
	CLR.L D5
	CLR.L D3
	CLR.L D6
	MOVE.W 12(A6),D5 *desc
	MOVE.W 14(A6),D3   *tam
	CMP.W #0,D5
       	BEQ ESP_SCANA
       	CMP.W #1,D5
	BEQ ESP_SCANA
      	MOVE.L #$FFFFFFFF,D0
	BRA  FI_SCAN

ESP_SCANA:
	CLR.L D0
	MOVE.W D5,D0
	BSR LEECAR
	CMP.L #-1,D0
	BEQ FIN_SCANU  *buffer vacio, hemos terminado 
	MOVE.B D0,(A1)+
	ADD.L #1,D6
	SUB.W #1,D3
	BNE ESP_SCANA

FIN_SCANU:
	MOVE.L D6,D0

FI_SCAN:
	MOVE.L -16(A6),A1
        MOVE.L -12(A6),D3
        MOVE.L -8(A6),D6
        MOVE.L -4(A6),D5
	UNLK A6
	RTS
	

**************************** FIN PRINT *********************************************

************************ COMIENZO RTI OJOOOO ***************************************

RTI:	 
	MOVEM.L D0-D2,-(A7)

RUTINARBU: 
	MOVE.B ISR,D2
	AND.B IMR2,D2
	BTST #1,D2
	BNE BUARA
	BTST #0,D2
	BNE ALATRANS
	BTST #5,D2
	BNE BUARB
	BTST #4,D2
	BNE BLATRANS
	BRA FINRTI

*ACORDARSE DE REVISAR ESTO DANI

BUARA: MOVE.B RBA,D1
      CLR.L D0
      BSR ESCCAR
      CMP.L #-1,D0
      BEQ FINRTI
      BRA RUTINARBU
      
BUARB: CLR.L D1
      MOVE.B RBB,D1
      MOVE.L #1,D0
      BSR  ESCCAR
      CMP.L #-1,D0
      BEQ FINRTI
      BRA RUTINARBU
      
COMPRIMRBB:
	BCLR #4,IMR2
        MOVE.B IMR2,IMR
        BRA RUTINARBU 
   
BLATRANS: 
	MOVE.L #3,D0
        BSR LEECAR 
        CMP.L #-1,D0
        BEQ COMPRIMRBB
        MOVE.B D0,TBB
        BRA RUTINARBU

COMPRIA:    
	BCLR #0,IMR2
        MOVE.B IMR2,IMR
        BRA RUTINARBU
        
           
ALATRANS: 
	MOVE.L #2,D0
        BSR LEECAR
        CMP.L #-1,D0
        BEQ COMPRIA
        MOVE.B D0,TBA
        BRA RUTINARBU
        
         
FINRTI: MOVEM.L (A7)+,D0-D2
      RTE

**********PROGRAMA PRINCIPAL********************************************************************
                                                                                       *
            BUFFER: DS.B 2100       * Buffer para lectura y escritura de caracteres
            PARDIR: DC.L 0          * Direccion que se pasa como parametro
            PARTAM: DC.W 0          * Tamano que se pasa como parametro
            CONTC:  DC.W 0           * Contador de caracteres a imprimir
            DESA:   EQU 0             * Descriptor linea A
            DESB:   EQU 1             * Descriptor linea B
            TAMBS:  EQU 3          * Tamano de bloque para SCAN
            TAMBP:  EQU 3           * Tamano de bloque para PRINT

INICIO:     MOVE.L  #BUS_ERR,8      * bus error handler
            MOVE.L  #ADR_ERR,12     * address error handler
            MOVE.L  #ILL_INS,16     * illegal instruction handler
            MOVE.L  #PRIVI_VIOL,32  * privilege violation handler
            MOVE.L  #ILL_INS,40     * illegal instruction handler
            MOVE.L  #ILL_INS,44     * illegal instruction handler

            BSR     INIT            * iniciar el programa
            MOVE.W  #$2000,SR       * permitir interrupciones (RE)
            
            *DS.W    1              * reserva una palabra para even

BUCPR:      MOVE.W  #TAMBS,PARTAM        * Inicializa parametro de tamanno
            MOVE.L  #BUFFER,PARDIR       * Parametro BUFFER = comienzo del buffer
OTRAL:      MOVE.W  PARTAM,-(A7)         * Tamano de bloque
            MOVE.W  #DESA,-(A7)          * Puerto A
            MOVE.L  PARDIR,-(A7)         * Direccion de lectura
ESPL:       BSR     SCAN
            ADD.L   #8,A7                * Restablece la pila
            ADD.L   D0,PARDIR            * Calcula la nueva direccion de lectura
            SUB.W   D0,PARTAM            * Actualiza el numero de caracteres leıdos
            BNE     OTRAL                * Si no se han leido todas los caracteres
                                         * del bloque se vuelve a leer
            MOVE.W  #TAMBS,CONTC         * Inicializa contador de caracteres a imprimir
            MOVE.L  #BUFFER,PARDIR       * Parametro BUFFER = comienzo del buffer
OTRAE:      MOVE.W  #TAMBP,PARTAM        * Tamano de escritura = Tamano de bloque
ESPE:       MOVE.W  PARTAM,-(A7)         * Tamano de escritura
            MOVE.W  #DESA,-(A7)          * Puerto A
            MOVE.L  PARDIR,-(A7)         * Direccion de escritura
            BSR     PRINT

            ADD.L   #8,A7                 * Restablece la pila
            ADD.L   D0,PARDIR             * Calcula la nueva direccion del buffer
            SUB.W   D0,CONTC              * Actualiza el contador de caracteres
            BEQ     SALIR                 * Si no quedan caracteres se acaba
            SUB.W   D0,PARTAM             * Actualiza el tamano de escritura
            BNE     ESPE                  * Si no se ha escrito todo el bloque se insiste
            CMP.W   #TAMBP,CONTC          * Si el no de caracteres que quedan es menor que
                                          * el tamano establecido se imprime ese n´umero
            BHI     OTRAE                 * Siguiente bloque
            MOVE.W  CONTC,PARTAM
            BRA     ESPE                    * Siguiente bloque
SALIR:      BRA     BUCPR

BUS_ERR:    BREAK                   * Bus Error Handler
            NOP                     *
ADR_ERR:    BREAK                   * Address Error Handler
            NOP                     *
ILL_INS:    BREAK                   * Illegal Instruction Handler
            NOP                     *
PRIVI_VIOL: BREAK                   * Privilege Violation Handler
            NOP                     *

**----------------



 
INCLUDE bib_aux.s

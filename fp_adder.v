//400101367

`timescale 1ns/1ns

module fp_adder (
   input [31:0] a, 
   input [31:0] b, 
   output [31:0] s

   );


wire [7:0]  Exponent_a;
wire [7:0]  Exponent_b;
wire [7:0]  Exponent_s;
wire [7:0]  UnpackExponent_a;
wire [25:0] UnpackFraction_a;
wire [7:0]  UnpackExponent_b;
wire [25:0] UnpackFraction_b;
wire [7:0]  bigE;
wire [25:0] leftsideAdder;
wire [26:0] leftsideAdderRightShift;
wire [27:0] leftsideAdderRS2comp;
wire [28:0] mainleft;
wire [25:0] rightsideadder;
wire [26:0] rightsideaddersticky;
wire [27:0] rightsideadder2Comp;
wire [28:0] mainright;
wire [8:0]  smallALU;
wire [28:0] BigADDERsignANDmagnitude;
wire [28:0] BigADDERout;
wire [7:0]  ExponentDifference;
wire [27:0] BigADDERmagnitude;
wire Borrow,sticky,rightsideadderSign,leftsideAdderSign;


assign Exponent_a = a[30:23];
assign Exponent_b = b[30:23];
assign UnpackExponent_a  = (Exponent_a==0) ? 1 : Exponent_a; 
assign UnpackFraction_a  = (Exponent_a==0) ? {1'b0 , a[22:0] , 2'b00} : {1'b1 , a[22:0] , 2'b00};
assign UnpackExponent_b  = (Exponent_b==0) ? 1 : Exponent_b; 
assign UnpackFraction_b  = (Exponent_b==0) ? {1'b0 , b[22:0] , 2'b00} : {1'b1 , b[22:0] , 2'b00};
assign smallALU   = UnpackExponent_a + (~UnpackExponent_b)+1;
assign Borrow = smallALU[8];
assign leftsideAdderSign  = Borrow ? a[31] : b[31];
assign rightsideadderSign = Borrow ? b[31] : a[31];
assign bigE  = Borrow ? UnpackExponent_b : UnpackExponent_a;
assign leftsideAdder  = Borrow ? UnpackFraction_a : UnpackFraction_b;
assign rightsideadder  = Borrow ? UnpackFraction_b : UnpackFraction_a;
assign ExponentDifference = Borrow ? 256 - smallALU[7:0] : smallALU[7:0];
assign sticky = |( leftsideAdder << 26 - ExponentDifference );
assign leftsideAdderRightShift = {leftsideAdder >> ExponentDifference , sticky};
assign leftsideAdderRS2comp = leftsideAdderSign ? {1'b1 , ~leftsideAdderRightShift + 1} : {1'b0 , leftsideAdderRightShift};
assign mainleft = {leftsideAdderRS2comp[27] , leftsideAdderRS2comp};
assign rightsideaddersticky = {rightsideadder , 1'b0};
assign rightsideadder2Comp  = rightsideadderSign ? {1'b1 , ~rightsideaddersticky + 1} : {1'b0 , rightsideaddersticky};
assign mainright = {rightsideadder2Comp[27] , rightsideadder2Comp};
assign BigADDERout = mainleft + mainright;
assign BigADDERsignANDmagnitude  = BigADDERout[28] ? {1'b1 , ~BigADDERout[27:0] + 1'b1} : BigADDERout;
assign BigADDERmagnitude = BigADDERsignANDmagnitude[27:0];


wire [5:0] one_check;
assign one_check =      BigADDERmagnitude[27] ? 27 :
                        BigADDERmagnitude[26] ? 26 :
                        BigADDERmagnitude[25] ? 25 :
                        BigADDERmagnitude[24] ? 24 :
                        BigADDERmagnitude[23] ? 23 :
                        BigADDERmagnitude[22] ? 22 :
                        BigADDERmagnitude[21] ? 21 :
                        BigADDERmagnitude[20] ? 20 :
                        BigADDERmagnitude[19] ? 19 :
                        BigADDERmagnitude[18] ? 18 :
                        BigADDERmagnitude[17] ? 17 :
                        BigADDERmagnitude[16] ? 16 :
                        BigADDERmagnitude[15] ? 15 :
                        BigADDERmagnitude[14] ? 14 :
                        BigADDERmagnitude[13] ? 13 :
                        BigADDERmagnitude[12] ? 12 :
                        BigADDERmagnitude[11] ? 11 :
                        BigADDERmagnitude[10] ? 10 :
                        BigADDERmagnitude[9]  ? 9  :
                        BigADDERmagnitude[8]  ? 8  :
                        BigADDERmagnitude[7]  ? 7  :
                        BigADDERmagnitude[6]  ? 6  :
                        BigADDERmagnitude[5]  ? 5  :
                        BigADDERmagnitude[4]  ? 4  :
                        BigADDERmagnitude[3]  ? 3  :
                        BigADDERmagnitude[2]  ? 2  :
                        BigADDERmagnitude[1]  ? 1  : 0;

wire no_shift;
wire [27:0] no_shift_Fraction;
assign no_shift = one_check == 26 ? 1 : 0;
assign no_shift_Fraction = BigADDERmagnitude;


wire onebit_rightshift;
wire [27:0] onebit_rightshift_Fraction;
assign onebit_rightshift =  one_check == 27 ? 1 : 0;
assign onebit_rightshift_Fraction = {BigADDERmagnitude[27:1] >> 1 , |BigADDERmagnitude[1:0]};


wire Elessthanshift;
assign Elessthanshift = 27 - one_check > bigE ? 1 : 0;


wire nbit_leftshift;
wire [5:0] nbit_leftshift_amount; 
wire [27:0] nbit_leftshift_Fraction;
assign nbit_leftshift = one_check<26 && (bigE!=1) ? 1 : 0;
assign nbit_leftshift_amount = Elessthanshift ? bigE-1 : 26 - one_check;
assign nbit_leftshift_Fraction = BigADDERmagnitude << nbit_leftshift_amount;


wire denormalized;
wire [27:0] denormalized_Fraction;
assign denormalized = bigE == 1 && one_check<26 ? 1 : 0;
assign denormalized_Fraction = BigADDERmagnitude;


wire [7:0] first_trail_E_S;
assign first_trail_E_S = BigADDERmagnitude == 0 || denormalized ? 0 : no_shift ? bigE : onebit_rightshift ? bigE + 1 : nbit_leftshift && Elessthanshift ? 0 : bigE - nbit_leftshift_amount;


wire [27:0] first_trail_F_S;
assign first_trail_F_S = BigADDERmagnitude == 0 ? 0 : denormalized ? denormalized_Fraction : no_shift ? no_shift_Fraction : onebit_rightshift ? onebit_rightshift_Fraction : nbit_leftshift ? nbit_leftshift_Fraction : 0;


wire [24:0] rounding;
assign rounding = first_trail_F_S[2] == 0 ? first_trail_F_S[27:3] : first_trail_F_S[2:0] > 4 ? first_trail_F_S[27:3] + 1 : first_trail_F_S[2:0] == 4 && first_trail_F_S[3] == 0 ? first_trail_F_S[27:3] : first_trail_F_S[27:3] + 1 ;


wire [7:0] final_E_S;
assign final_E_S =  rounding[24] ? first_trail_E_S + 1 : first_trail_E_S;

wire [24:0] final_F_S;
assign final_F_S =  rounding[24] ? rounding >> 1 : rounding;


assign s = {BigADDERsignANDmagnitude[28], final_E_S, final_F_S[22:0]};

endmodule
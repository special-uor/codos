###################################################################
## Import modules###################################################
###################################################################
from scipy.optimize import fsolve #So we can perform minimisation
import numpy as np  
# from math import acos, cos 

class P_model_inverter:
    # Define various constants
    omega = 3
    lam = 2.45 # Latent heat of vaporisation (MJ kg^-1)
    gamma = 0.067 # psychrometer constant (kPa K^-1)

    a = 0.6108
    b = 17.27
    c = 237.3
    abc = 2503.1628468 # a * b * c

    dark_scale = 0.025
    visc_offset = 138

    R_o = 400
    R = 8.314 # Universal gas constant (J mol^-1 K^-1)

    dHc = 79430 # Carbon activation energy (J mol^-1)
    dHo = 36380 # Oxygen activation energy (J mol^-1)
    delta_H = 37830 # Compensation point activation energy (J mol^-1)

    O = 210 #Atmospheric concentration of oxygen
    C = 14.76

    modern_CO2 = 340 # Modern CO2 concentration in ppm

    D_root_factor = 4

    solver_args = None

    # Initalise given the reference variables 
    def __init__(self, T_diff, T_ref, m_rec, c_ratio, lat=-30, *args):
        # Set given values
        self.solver_args = args

        self.lat = lat

        self.T_rec = T_diff + T_ref 
        self.T_ref = T_ref
        self.m_rec = m_rec
        self.c_ratio = c_ratio

        # Precalculate some variables that don't change for changing true MI
        self.K_rec = K(self.T_rec) 
        self.K_ref = K(self.T_ref)

        self.eta_rec = eta(self.T_rec)   
        self.eta_ref = eta(self.T_ref)

        self.E_q_sec_rec = pre_section_E_q(self.T_rec)
        self.E_q_sec_ref = pre_section_E_q(self.T_ref)
        
        self.use_e_pre = self.c_ratio*( self.useable_e(self.T_ref, self.m_rec, self.K_ref, self.eta_ref, self.E_q_sec_ref) ) #Is c_ratio on the correct side here?
       
    # Find the optimal MI given the set variables
    def solve_for_delta_m(self):
        return abs(fsolve(self.e_difference, 1, *self.solver_args)[0]) - self.m_rec #The 1 here is because the valve is most likely between 0 and 3 

    def e_difference(self, m_true):
        m_true = abs(m_true)       
        return abs(self.useable_e(self.T_rec, m_true, self.K_rec, self.eta_rec, self.E_q_sec_rec) - self.use_e_pre)
        
    # The version of E without unnecessary constants
    def useable_e(self, T, m, pre_K, pre_eta, pre_sec_E_q):
        pre_E_q = pre_calc_E_q(T,m, pre_sec_E_q) # We precalculate E_q so we don't have to calculate it twice in the different eqm functions
        cur_eqm = abs(eqm(pre_E_q, m))
        return cur_eqm * (self.C*pow(pre_eta/pre_K, 1/2) * pow(cur_eqm, 1/P_model_inverter.D_root_factor) + 1) **(-1)
   
    # Internal c_i for the plant
    def get_c_i(self):
        return c_i(self.T_rec, self.c_ratio*self.modern_CO2, self.m_rec)

    # Determines if the compensation point 'law' is upheld
    def compensation_point_held(self, m):
        return c_i(self.T_rec, self.c_ratio*self.modern_CO2, m) > true_compensation_point(self.T_rec) 

###################################################################
## Static methods for the P_model_inverter class ##################
###################################################################
def eqm(pre_E_q, m):
    return pre_E_q * ( pow(abs(1 + pow(m, P_model_inverter.omega)), 1/P_model_inverter.omega) - m ) #TODO: This abs is extremely suspect however this should be fine when m>0

# We can precalculate a lot of the E_q hence we wont use this function much
def E_q(T, m):
    return R_n(T,m)/P_model_inverter.lam * pow(1 + P_model_inverter.gamma * pow(P_model_inverter.c+T, 2)/(P_model_inverter.abc) * np.exp(-P_model_inverter.b*T/(P_model_inverter.c + T)),-1)

def pre_calc_E_q(T, m, pre):
    return R_n(T, m)*pre

def pre_section_E_q(T):
    return pow(1 + P_model_inverter.gamma * pow(P_model_inverter.c+T, 2)/(P_model_inverter.abc) * np.exp(-P_model_inverter.b*T/(P_model_inverter.c + T)),-1)/P_model_inverter.lam

# Gives the value for R_n in MJ kg^(-1) a^(-1) mm
def R_n(T, m, lat=-30):
    scale_factor = 365.24*24*60*60*10**(-6)
    return scale_factor*(0.83*P_model_inverter.R_o*(0.25 + 0.5*S_f(m)) - (107 - T)*(0.2 + 0.8*S_f(m)))

# Fraction of sunshine hours
def S_f(m):
    return 0.6611 * np.exp(-0.74*m) + 0.2175

def K(T):
    pre_calc = 1/P_model_inverter.R*(1/298 - 1/(T + 273.15)) #Don't have a better name for this
    return 404.9 * np.exp(P_model_inverter.dHc * pre_calc) * ( 1 + P_model_inverter.O/(278.4 * np.exp(P_model_inverter.dHo * pre_calc)))

def eta(T):
    return 0.024258 * np.exp(580/(T+P_model_inverter.visc_offset))

# Calculates c_i, could be sped up
def c_i(T, c_a, m):
    return c_a/c_a_c_i_ratio(T, m)

def c_a_c_i_ratio(T, m):
    delta_e = eqm(E_q(T,m), m)
    return 1+ P_model_inverter.C*(eta(T)/K(T))**(1/2) * delta_e**(1/P_model_inverter.D_root_factor)

def compensation_point(T):
    return 42.75*np.exp((P_model_inverter.delta_H/P_model_inverter.R)*(1/298 - 1/(273.15 + T)))

def true_compensation_point(T):
    return compensation_point(T) + P_model_inverter.dark_scale*K(T)

# Budyko relationship to give alpha from mi
def alpha_from_mi_om3(mi):
    return 1 + mi - (1+mi**3)**(1/3)

###################################################################
## Wrapper functions to find corrected moisture index #############
###################################################################
def calculate_m_true(T_diff, T_ref, m_rec, c_a_diff):
    model = P_model_inverter(T_diff, T_ref, m_rec, c_a_diff)
    
    delta_m = model.solve_for_delta_m()
    comp_point_held = model.compensation_point_held(m_rec)

    output = m_rec
    if comp_point_held:
        output += delta_m 


    return [output, comp_point_held, model.get_c_i()]

###################################################################
## Main ###########################################################
###################################################################
# if __name__ == "__main__":
#    present_temp = 20
#    past_temp = 15
#    reconstructed_mi = 1.2
#    modern_c_a = P_model_inverter.modern_CO2 
#    past_c_a = 250.0   
    
#    result = calculate_m_true(past_temp - present_temp, present_temp, reconstructed_mi, past_c_a/modern_c_a)
#    print("New moisture index:               ", result[0])
#    print("Has the compensation point held?: ", result[1])
#    print("Internal c_i for original values: ", result[2])
    
    
    
    
###################################################################
    
import pandas as pd
m0 = pd.read_csv('mi_input.csv') 


i = 0
result = list(['0'])
compensation = list(['0'])
internal_c_i = list(['0'])

#for m in (m0.loc[:])['age']:
#    print (m)

for i in range(len(m0)):  
    m2 = m0.loc[i]
    ca_temp = m2['past_temp'] - m2['present_t']
    ca_co2 = m2['past_co2']/m2['modern_co2']
    m3 = calculate_m_true(ca_temp, m2['present_t'], m2['recon_mi'], ca_co2)
    result = result + list([m3[0]])
    compensation = compensation+list([m3[1]])  
    internal_c_i = internal_c_i+list([m3[2]])

    
output_r={"result":result,
          "compensation":compensation,
          "internal_c_i":internal_c_i}
output_result=pd.DataFrame(output_r)
output_result=output_result.drop([0])
output_result.to_csv("output_result_.csv", sep=',')   
import numpy as np
from scipy.constants import c as clight

# !start-simulation-settings!

##### Machine parameters
circumference = 27000.0
machine_radius = circumference / (2*np.pi)

##### Parameters for the impedance model
plane = 'x'             
wake_type = 'dipolar'
wake_table = 'wake_lhc_injection.dat'

##### Initial offset to the particles x coordinate
initial_offset = 10.0e-6

##### Acceleration parameters
energy_gain_per_turn = 0
main_rf_phase = 180

##### RF parameters
h_RF = np.array([35640,])
V_RF = np.array([8.0e6])
dphi_RF = np.array([main_rf_phase,])
f_rev = 299792458 / circumference
omega_rev = 2*np.pi*f_rev
f_RF = np.array([f_rev*h for h in h_RF])

##### Optics parameters
alphap = 3.48e-4

Qx_frac = 0.275
Qy_frac = 0.295
Qx_int = 64
Qy_int = 59

Qx = Qx_int + Qx_frac
Qy = Qy_int + Qy_frac

##### Chromaticity
chromaticity = 0
print('Qp:', chromaticity)

##### Bunch parameters
p0c = 450.0e9
bucket_length = circumference / h_RF[0]
nemitt_x = 2.0e-6
nemitt_y = 2.0e-6
taub = 1.0e-9    # Full bunch length (4*sigma_z)
sigma_z = taub * clight / 4

# We use a limited amount of MP to have a general view of the wake effects
n_macroparticles = int(10_000)
num_slices = int(100)

# Bunch intensity scan
delta_bint = 0.3e12
bunch_intensity_scan = np.arange(0.1e12, 2.3e12, delta_bint)
print('Bunch intensity scan:', bunch_intensity_scan)

# Number of turns simulated
number_of_turns = 3_000

# !end-simulation-settings!
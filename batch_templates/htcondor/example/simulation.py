import os

import numpy as np
import pandas as pd
import h5py

import pickle

import xtrack as xt
import xpart as xp
import xwakes as xw
import xobjects as xo
import xfields as xf

from scipy.constants import c as clight

import matplotlib as mpl
import matplotlib.pyplot as plt
from sim_params import *

# Read wake table
wake_hllhc = xw.read_headtail_file(wake_table, ['time', 'dipole_x', 'dipole_y', 'quadrupolar_x', 'quadrupolar_y'])
wake_for_tracking_hllhc = xw.WakeFromTable(table=wake_hllhc, columns=['dipole_x'])
# Configure the wake for tracking
wake_for_tracking = wake_for_tracking_hllhc
wake_for_tracking.configure_for_tracking(
    zeta_range=(-0.375, 0.375),
    num_slices=num_slices,
    num_turns=1,
)
# Create the reference particle for xtrack
reference_particle = xt.Particles(mass0=xp.PROTON_MASS_EV, p0c=p0c)
beta0 = reference_particle.beta0[0]
gamma0 = reference_particle.gamma0[0]

# The line for Q' = 0 will be used for the twiss
segment_map = xt.LineSegmentMap(
    length=circumference,
    betx=machine_radius/Qx, bety=machine_radius/Qy,
    dnqx=[Qx_frac, 0], dnqy=[Qy_frac, 0],
    longitudinal_mode='linear_fixed_rf',
    voltage_rf=V_RF, frequency_rf=f_RF,
    lag_rf=dphi_RF, momentum_compaction_factor=alphap
    )

# Construct the full OTM with line segments and WF elements
one_turn_map_elements = [segment_map,]

# Compile the line
reference_line = xt.Line(one_turn_map_elements)
reference_line.particle_ref = reference_particle

# Compute the twiss parameters
tw = reference_line.twiss()
Qs = tw.qs
eta = tw.slip_factor
print(f'Qs = {Qs}, eta = {eta}')

print(f'Simulation for b_int = {bunch_intensity:.2e}')

segment_map = xt.LineSegmentMap(
    length=circumference,
    betx=machine_radius/Qx, bety=machine_radius/Qy,
    dnqx=[Qx_frac, chromaticity], dnqy=[Qy_frac, chromaticity],
    longitudinal_mode='linear_fixed_rf',
    voltage_rf=V_RF, frequency_rf=f_RF,
    lag_rf=dphi_RF, momentum_compaction_factor=alphap
    )
# Create monitors at each RF station
# initialize a monitor for the average transverse positions
flush_data_every = int(500)
particle_monitor_mask = np.full(n_macroparticles, False, dtype=bool)
particle_monitor_mask[0:5] = True
    
monitor = xf.CollectiveMonitor(
    base_file_name=f'./bunchmonitor_with_bellows_bint_{bunch_intensity:.2e}',
    monitor_bunches=True,
    monitor_slices=True,
    monitor_particles=False,
    particle_monitor_mask=particle_monitor_mask,
    flush_data_every=flush_data_every,
    stats_to_store=['mean_x', 'mean_y', 'mean_px', 'sigma_x', 'epsn_x', 'num_particles'],
    stats_to_store_particles=['x', 'px'],
    backend='hdf5',
    zeta_range=(-0.3*bucket_length, 0.3*bucket_length),
    num_slices=num_slices//2,
    bunch_spacing_zeta=circumference,
)

# Construct the full OTM with line segments and WF elements
one_turn_map_elements = [monitor, segment_map, wake_for_tracking]

# Compile the line
line = xt.Line(one_turn_map_elements)
line.particle_ref = reference_particle
line.build_tracker()

# initialize a matched gaussian bunch
particles = xp.generate_matched_gaussian_bunch(
    num_particles=n_macroparticles,
    total_intensity_particles=bunch_intensity,
    nemitt_x=nemitt_x, nemitt_y=nemitt_y,
    sigma_z=sigma_z,
    line=line,
)

# apply a kick to the particles
particles.x += initial_offset

turn_range = np.arange(0, number_of_turns, 1)

# Track
line.track(particles, num_turns=number_of_turns, with_progress=True)
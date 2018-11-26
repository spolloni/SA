import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.cm as cm
plt.style.use('seaborn-white')
import numpy as np

df= pd.read_csv("../../../Output/GAUTENG/gradplots/lowess.csv")
df_placebo = df[df.placebo==1]
df_rdp = df[df.placebo==0]

#plt.contour(df_placebo.prede, df_placebo.mo2con_joined, df_placebo.rdists, colors='black');

#X, Y = np.meshgrid(df_placebo.mo2con_joined, df_placebo.rdists)

# plt.scatter(
#     df_placebo.rdists,
#     df_placebo.mo2con_reg_joined,
#     c=df_placebo.prede,
#     s=200,
#     cmap=cm.Reds,
#     marker='s'
# )
# plt.show()

plt.scatter(
    df_rdp.rdists,
    df_rdp.mo2con_reg_joined,
    c=df_rdp.prede,
    s=200,
    cmap=cm.Reds,
    marker='s'
)
plt.show()








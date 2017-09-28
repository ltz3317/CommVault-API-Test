# CommVault-API-Test
Shell scripts for testing CommVault (or HDPS) v11 configuration via API

# Steps:
1. Install xmlstarlet.
2. Set environment parameters in setenv.sh.
3. Set test case parameters in testcase.sh.
4. Run showall.sh to show current configuration in HDPS.
5. Run updateall.sh to update configuration via API.
6. Run fallback.sh to fallback the configuration.

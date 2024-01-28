# download to runpod pod to path: '/'. Docker command in template:

# bash -c '
# wget https://github.com/thander/runpod-deploy/blob/main/pre_start.sh -O /pre_start.sh;
# /start.sh;
# ';

echo \"**** syncing venv to workspace, please wait. This could take a while on first startup! ****\"

ln -s /runpod-volume/venv /workspace/

echo \"**** load models ****\"

echo \"**** syncing stable diffusion to workspace, please wait ****\"

rm -rf /workspace/stable-diffusion-webui
ln -s /runpod-volume/my-stable-diffusion-webui /workspace/stable-diffusion-webui

echo \"**** load extensions and weights ****\"

if ! grep -q -- "--xformers --api --nowebui --skip-install" /workspace/stable-diffusion-webui/webui-user.sh; then
  sed -i 's/--xformers/--xformers --api --nowebui --skip-install/' /workspace/stable-diffusion-webui/webui-user.sh;
fi

if [[ $RUNPOD_STOP_AUTO ]]
then
  echo \"Skipping auto-start of webui\"
else  echo \"Started webui through relauncher script\"
  cd /workspace/stable-diffusion-webui
  rm log.log
  python relauncher.py > log.log &

  cd /runpod-volume/app
  rm -rf schemas/__pycache__
  git pull
  grep -q 'Model loaded in' <(tail -f /workspace/stable-diffusion-webui/log.log)
  nohup python -u handler.py &
fi

#!/bin/sh
set -e
set -u
set -o pipefail

function on_error {
  echo "$(realpath -mq "${0}"):$1: error: Unexpected failure"
}
trap 'on_error $LINENO' ERR

if [ -z ${UNLOCALIZED_RESOURCES_FOLDER_PATH+x} ]; then
  # If UNLOCALIZED_RESOURCES_FOLDER_PATH is not set, then there's nowhere for us to copy
  # resources to, so exit 0 (signalling the script phase was successful).
  exit 0
fi

mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"

RESOURCES_TO_COPY=${PODS_ROOT}/resources-to-copy-${TARGETNAME}.txt
> "$RESOURCES_TO_COPY"

XCASSET_FILES=()

# This protects against multiple targets copying the same framework dependency at the same time. The solution
# was originally proposed here: https://lists.samba.org/archive/rsync/2008-February/020158.html
RSYNC_PROTECT_TMP_FILES=(--filter "P .*.??????")

case "${TARGETED_DEVICE_FAMILY:-}" in
  1,2)
    TARGET_DEVICE_ARGS="--target-device ipad --target-device iphone"
    ;;
  1)
    TARGET_DEVICE_ARGS="--target-device iphone"
    ;;
  2)
    TARGET_DEVICE_ARGS="--target-device ipad"
    ;;
  3)
    TARGET_DEVICE_ARGS="--target-device tv"
    ;;
  4)
    TARGET_DEVICE_ARGS="--target-device watch"
    ;;
  *)
    TARGET_DEVICE_ARGS="--target-device mac"
    ;;
esac

install_resource()
{
  if [[ "$1" = /* ]] ; then
    RESOURCE_PATH="$1"
  else
    RESOURCE_PATH="${PODS_ROOT}/$1"
  fi
  if [[ ! -e "$RESOURCE_PATH" ]] ; then
    cat << EOM
error: Resource "$RESOURCE_PATH" not found. Run 'pod install' to update the copy resources script.
EOM
    exit 1
  fi
  case $RESOURCE_PATH in
    *.storyboard)
      echo "ibtool --reference-external-strings-file --errors --warnings --notices --minimum-deployment-target ${!DEPLOYMENT_TARGET_SETTING_NAME} --output-format human-readable-text --compile ${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$RESOURCE_PATH\" .storyboard`.storyboardc $RESOURCE_PATH --sdk ${SDKROOT} ${TARGET_DEVICE_ARGS}" || true
      ibtool --reference-external-strings-file --errors --warnings --notices --minimum-deployment-target ${!DEPLOYMENT_TARGET_SETTING_NAME} --output-format human-readable-text --compile "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$RESOURCE_PATH\" .storyboard`.storyboardc" "$RESOURCE_PATH" --sdk "${SDKROOT}" ${TARGET_DEVICE_ARGS}
      ;;
    *.xib)
      echo "ibtool --reference-external-strings-file --errors --warnings --notices --minimum-deployment-target ${!DEPLOYMENT_TARGET_SETTING_NAME} --output-format human-readable-text --compile ${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$RESOURCE_PATH\" .xib`.nib $RESOURCE_PATH --sdk ${SDKROOT} ${TARGET_DEVICE_ARGS}" || true
      ibtool --reference-external-strings-file --errors --warnings --notices --minimum-deployment-target ${!DEPLOYMENT_TARGET_SETTING_NAME} --output-format human-readable-text --compile "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$RESOURCE_PATH\" .xib`.nib" "$RESOURCE_PATH" --sdk "${SDKROOT}" ${TARGET_DEVICE_ARGS}
      ;;
    *.framework)
      echo "mkdir -p ${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}" || true
      mkdir -p "${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      echo "rsync --delete -av "${RSYNC_PROTECT_TMP_FILES[@]}" $RESOURCE_PATH ${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}" || true
      rsync --delete -av "${RSYNC_PROTECT_TMP_FILES[@]}" "$RESOURCE_PATH" "${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      ;;
    *.xcdatamodel)
      echo "xcrun momc \"$RESOURCE_PATH\" \"${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH"`.mom\"" || true
      xcrun momc "$RESOURCE_PATH" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcdatamodel`.mom"
      ;;
    *.xcdatamodeld)
      echo "xcrun momc \"$RESOURCE_PATH\" \"${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcdatamodeld`.momd\"" || true
      xcrun momc "$RESOURCE_PATH" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcdatamodeld`.momd"
      ;;
    *.xcmappingmodel)
      echo "xcrun mapc \"$RESOURCE_PATH\" \"${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcmappingmodel`.cdm\"" || true
      xcrun mapc "$RESOURCE_PATH" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcmappingmodel`.cdm"
      ;;
    *.xcassets)
      ABSOLUTE_XCASSET_FILE="$RESOURCE_PATH"
      XCASSET_FILES+=("$ABSOLUTE_XCASSET_FILE")
      ;;
    *)
      echo "$RESOURCE_PATH" || true
      echo "$RESOURCE_PATH" >> "$RESOURCES_TO_COPY"
      ;;
  esac
}
if [[ "$CONFIGURATION" == "Debug" ]]; then
  install_resource "${PODS_ROOT}/MJRefresh/MJRefresh/MJRefresh.bundle"
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/TYAlertView/TYAlertView.bundle"
  install_resource "${PODS_ROOT}/TYAvatarEditKit/TYAvatarEditKit-0.1.4-rc.1/Assets/bundles/TYCropViewControllerBundle.bundle"
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/TYHybridContainer/TYHybridContainer.bundle"
  install_resource "${PODS_ROOT}/TYNavigationController/TYNavigationController-1.13.0-rc.2/Assets/bundles/TYNavigationRes.bundle"
  install_resource "${PODS_ROOT}/TYOEMConfig/TYOEMConfig-1.21.1-tybizbundle.3.22.0-2-rc.1/Assets/resources/customColor.plist"
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/TYSmartActionDialog/TYSmartActionDialog.bundle"
  install_resource "${PODS_ROOT}/TYSmartBusinessLibrary/TYSmartBusinessLibrary-3.22.0-rc.7/Assets/resources/cell_view_arrow@2x.png"
  install_resource "${PODS_ROOT}/TYSmartBusinessLibrary/TYSmartBusinessLibrary-3.22.0-rc.7/Assets/resources/cell_view_arrow@3x.png"
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/TYSmartBusinessLibrary/TPViews.bundle"
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/TYSmartBusinessLibrary/TYSmartBusinessLibraryRes.bundle"
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/TYVideoPlayer/TYVideoPlayer.bundle"
  install_resource "${PODS_ROOT}/TuyaSmartBaseKit/ios/TuyaSmartBaseKit.framework/Versions/A/Resources/cerficate_v2"
  install_resource "${PODS_ROOT}/TuyaSmartBizCore/TuyaSmartBizCore-3.22.0-rc.3/Assets/resources/custom.json"
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/TuyaSmartBizCore/TuyaSmartBizCore.bundle"
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/TuyaSmartCloudServiceBizBundle/TuyaSmartCloudServiceBizBundle.bundle"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/cell_view_arrow@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/cell_view_arrow@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/ty_customColor.plist"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/en.lproj/Localizable.strings"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/en.lproj/TPViewsLocalizable.strings"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/phoneCodeList.plist"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/tp_top_bar_back@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/tp_top_bar_back@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/tysmart_selected@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/tysmart_selected@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/ty_mainbt_about@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/ty_mainbt_about@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/ty_mainbt_about_active@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/ty_mainbt_about_active@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/ty_mainbt_add@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/ty_mainbt_add@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/ty_mainbt_add_active@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/ty_mainbt_add_active@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/ty_mainbt_devicelist@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/ty_mainbt_devicelist@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/ty_mainbt_devicelist_active@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/ty_mainbt_devicelist_active@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/zh-Hans.lproj/Localizable.strings"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/zh-Hans.lproj/TPViewsLocalizable.strings"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/en.lproj"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/zh-Hans.lproj"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/power_off@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/power_off@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/power_on@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/power_on@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_devicelist_dot_gray@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_devicelist_dot_gray@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_devicelist_dot_green@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_devicelist_dot_green@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_devicelist_share_gray@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_devicelist_share_gray@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_devicelist_share_green@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_devicelist_share_green@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_list_empty@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_list_empty@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_panel_arrows@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_panel_arrows@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_panel_minus@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_panel_minus@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_panel_plus@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_panel_plus@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_panel_select@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_panel_select@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/pps_left_arrow@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/pps_left_arrow@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/pps_right_arrow@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/pps_right_arrow@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_cloud_icon@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_cloud_icon@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_control_hd_normal@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_control_hd_normal@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_control_sd_normal@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_control_sd_normal@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_message@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_message@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_mic_icon@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_mic_icon@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_photo_icon@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_photo_icon@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_playback_icon@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_playback_icon@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_rec_icon@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_rec_icon@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_soundOff_icon@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_soundOff_icon@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_soundOn_icon@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_soundOn_icon@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_tool_delete_normal@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_tool_delete_normal@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_tool_download_normal@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_tool_download_normal@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_tool_pause_normal@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_tool_pause_normal@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_tool_play_normal@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_tool_play_normal@3x.png"
  install_resource "${PODS_ROOT}/TuyaSmartUtil/ios/TuyaSmartUtil.framework/Versions/A/Resources/TuyaSmartUtil.bundle"
fi
if [[ "$CONFIGURATION" == "Release" ]]; then
  install_resource "${PODS_ROOT}/MJRefresh/MJRefresh/MJRefresh.bundle"
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/TYAlertView/TYAlertView.bundle"
  install_resource "${PODS_ROOT}/TYAvatarEditKit/TYAvatarEditKit-0.1.4-rc.1/Assets/bundles/TYCropViewControllerBundle.bundle"
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/TYHybridContainer/TYHybridContainer.bundle"
  install_resource "${PODS_ROOT}/TYNavigationController/TYNavigationController-1.13.0-rc.2/Assets/bundles/TYNavigationRes.bundle"
  install_resource "${PODS_ROOT}/TYOEMConfig/TYOEMConfig-1.21.1-tybizbundle.3.22.0-2-rc.1/Assets/resources/customColor.plist"
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/TYSmartActionDialog/TYSmartActionDialog.bundle"
  install_resource "${PODS_ROOT}/TYSmartBusinessLibrary/TYSmartBusinessLibrary-3.22.0-rc.7/Assets/resources/cell_view_arrow@2x.png"
  install_resource "${PODS_ROOT}/TYSmartBusinessLibrary/TYSmartBusinessLibrary-3.22.0-rc.7/Assets/resources/cell_view_arrow@3x.png"
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/TYSmartBusinessLibrary/TPViews.bundle"
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/TYSmartBusinessLibrary/TYSmartBusinessLibraryRes.bundle"
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/TYVideoPlayer/TYVideoPlayer.bundle"
  install_resource "${PODS_ROOT}/TuyaSmartBaseKit/ios/TuyaSmartBaseKit.framework/Versions/A/Resources/cerficate_v2"
  install_resource "${PODS_ROOT}/TuyaSmartBizCore/TuyaSmartBizCore-3.22.0-rc.3/Assets/resources/custom.json"
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/TuyaSmartBizCore/TuyaSmartBizCore.bundle"
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/TuyaSmartCloudServiceBizBundle/TuyaSmartCloudServiceBizBundle.bundle"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/cell_view_arrow@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/cell_view_arrow@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/ty_customColor.plist"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/en.lproj/Localizable.strings"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/en.lproj/TPViewsLocalizable.strings"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/phoneCodeList.plist"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/tp_top_bar_back@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/tp_top_bar_back@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/tysmart_selected@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/tysmart_selected@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/ty_mainbt_about@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/ty_mainbt_about@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/ty_mainbt_about_active@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/ty_mainbt_about_active@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/ty_mainbt_add@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/ty_mainbt_add@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/ty_mainbt_add_active@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/ty_mainbt_add_active@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/ty_mainbt_devicelist@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/ty_mainbt_devicelist@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/ty_mainbt_devicelist_active@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/ty_mainbt_devicelist_active@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/zh-Hans.lproj/Localizable.strings"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/zh-Hans.lproj/TPViewsLocalizable.strings"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/en.lproj"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/Base/Assets/zh-Hans.lproj"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/power_off@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/power_off@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/power_on@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/power_on@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_devicelist_dot_gray@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_devicelist_dot_gray@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_devicelist_dot_green@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_devicelist_dot_green@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_devicelist_share_gray@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_devicelist_share_gray@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_devicelist_share_green@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_devicelist_share_green@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_list_empty@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_list_empty@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_panel_arrows@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_panel_arrows@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_panel_minus@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_panel_minus@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_panel_plus@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_panel_plus@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_panel_select@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/DeviceList/Assets/ty_panel_select@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/pps_left_arrow@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/pps_left_arrow@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/pps_right_arrow@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/pps_right_arrow@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_cloud_icon@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_cloud_icon@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_control_hd_normal@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_control_hd_normal@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_control_sd_normal@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_control_sd_normal@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_message@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_message@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_mic_icon@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_mic_icon@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_photo_icon@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_photo_icon@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_playback_icon@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_playback_icon@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_rec_icon@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_rec_icon@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_soundOff_icon@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_soundOff_icon@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_soundOn_icon@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_soundOn_icon@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_tool_delete_normal@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_tool_delete_normal@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_tool_download_normal@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_tool_download_normal@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_tool_pause_normal@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_tool_pause_normal@3x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_tool_play_normal@2x.png"
  install_resource "${PODS_ROOT}/../../TuyaSmartDemo/Classes/IPC/Assets/ty_camera_tool_play_normal@3x.png"
  install_resource "${PODS_ROOT}/TuyaSmartUtil/ios/TuyaSmartUtil.framework/Versions/A/Resources/TuyaSmartUtil.bundle"
fi

mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
rsync -avr --copy-links --no-relative --exclude '*/.svn/*' --files-from="$RESOURCES_TO_COPY" / "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
if [[ "${ACTION}" == "install" ]] && [[ "${SKIP_INSTALL}" == "NO" ]]; then
  mkdir -p "${INSTALL_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
  rsync -avr --copy-links --no-relative --exclude '*/.svn/*' --files-from="$RESOURCES_TO_COPY" / "${INSTALL_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
fi
rm -f "$RESOURCES_TO_COPY"

if [[ -n "${WRAPPER_EXTENSION}" ]] && [ "`xcrun --find actool`" ] && [ -n "${XCASSET_FILES:-}" ]
then
  # Find all other xcassets (this unfortunately includes those of path pods and other targets).
  OTHER_XCASSETS=$(find -L "$PWD" -iname "*.xcassets" -type d)
  while read line; do
    if [[ $line != "${PODS_ROOT}*" ]]; then
      XCASSET_FILES+=("$line")
    fi
  done <<<"$OTHER_XCASSETS"

  if [ -z ${ASSETCATALOG_COMPILER_APPICON_NAME+x} ]; then
    printf "%s\0" "${XCASSET_FILES[@]}" | xargs -0 xcrun actool --output-format human-readable-text --notices --warnings --platform "${PLATFORM_NAME}" --minimum-deployment-target "${!DEPLOYMENT_TARGET_SETTING_NAME}" ${TARGET_DEVICE_ARGS} --compress-pngs --compile "${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
  else
    printf "%s\0" "${XCASSET_FILES[@]}" | xargs -0 xcrun actool --output-format human-readable-text --notices --warnings --platform "${PLATFORM_NAME}" --minimum-deployment-target "${!DEPLOYMENT_TARGET_SETTING_NAME}" ${TARGET_DEVICE_ARGS} --compress-pngs --compile "${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}" --app-icon "${ASSETCATALOG_COMPILER_APPICON_NAME}" --output-partial-info-plist "${TARGET_TEMP_DIR}/assetcatalog_generated_info_cocoapods.plist"
  fi
fi

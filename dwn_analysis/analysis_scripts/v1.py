from datetime import datetime

from chime_ml.feature_library_v2.common.meta import (
    ACCOUNT_ACCESS_AND_UPDATE_TEAM_OWNER_INFO,
)
from chime_ml.feature_store_core.feature_library.abstract.base_family import (
    BaseFeatureFamilyTemplate,
)
from chime_ml.feature_store_core.feature_library.abstract.column import (
    BINARY,
    CATEGORICAL,
    P_DISCRETE,
    Column,
    FeatureColumn,
)
from chime_ml.feature_store_core.feature_library.abstract.cte_config import CTEConfig
from chime_ml.feature_store_core.feature_library.abstract.meta import (
    MetaOwnerInfo,
    MetaTag,
)
from chime_ml.feature_store_core.feature_library.abstract.window import (
    ComputeWindow,
    StreamWindow,
)
from chime_ml.feature_store_core.feature_library.common.columns import (
    LAST_EVENT_TIMESTAMP,
)
from chime_ml.feature_store_core.feature_library.common.materialization_configs import (
    build_deprecate_materialization_cfg,
)


class BaseFamilyTemplate(BaseFeatureFamilyTemplate):
    ff_template_name: str = "authn_session_id__login_nudata_data"
    version: str = "v1"
    description: str = "Feature Family to capture NuData score data and authn_session_id at login"
    entities: list[Column] = [Column(name="authn_session_id", type=CATEGORICAL)]

    cte_configs: dict[str, CTEConfig] = {}
    attributes: list[FeatureColumn] = [
        LAST_EVENT_TIMESTAMP,
        FeatureColumn(name="na__user_id", type=CATEGORICAL),
        FeatureColumn(name="na__originating_lifecycle_phase", type=CATEGORICAL),
        FeatureColumn(name="na__account_access_attempt_id", type=CATEGORICAL),
        FeatureColumn(name="is__nudata_response_missing", type=BINARY),
        FeatureColumn(name="na__device_uid", type=CATEGORICAL),
        FeatureColumn(name="na__score", type=CATEGORICAL),
        FeatureColumn(name="na__placement", type=CATEGORICAL),
        FeatureColumn(name="na__nudata_session_id", type=CATEGORICAL),
        FeatureColumn(name="na__unified_device_id", type=CATEGORICAL),
        FeatureColumn(name="na__device_first_seen", type=CATEGORICAL),
        FeatureColumn(name="na__device_last_seen", type=CATEGORICAL),
        FeatureColumn(name="na__browser_screen_info", type=CATEGORICAL),
        FeatureColumn(name="na__browser_timezone", type=CATEGORICAL),
        FeatureColumn(name="na__browser_language", type=CATEGORICAL),
        FeatureColumn(name="na__browser_plugin_signature", type=CATEGORICAL),
        FeatureColumn(name="is__browser_flash_installed", type=BINARY),
        FeatureColumn(name="na__browser_user_agent", type=CATEGORICAL),
        FeatureColumn(name="na__browser_webgl_signature", type=CATEGORICAL),
        FeatureColumn(name="is__browser_valid", type=BINARY),
        FeatureColumn(name="is__browser_invalid", type=BINARY),
        FeatureColumn(name="is__browser_tampered", type=BINARY),
        FeatureColumn(name="is__dfp_mismatch", type=BINARY),
        FeatureColumn(name="is__dfp_mismatch_version_2", type=BINARY),
        FeatureColumn(name="is__did_mismatch", type=BINARY),
        FeatureColumn(name="is__did_valid", type=BINARY),
        FeatureColumn(name="is__did_tampered", type=BINARY),
        FeatureColumn(name="is__did_missing_uid", type=BINARY),
        FeatureColumn(name="na__device_type", type=CATEGORICAL),
        FeatureColumn(name="is__device_type_mismatch", type=BINARY),
        FeatureColumn(name="is__device_mode_mismatch", type=BINARY),
        FeatureColumn(name="na__device_screen_resolution", type=CATEGORICAL),
        FeatureColumn(name="is__device_screen_resolution_mismatch", type=BINARY),
        FeatureColumn(name="is__device_tampered", type=BINARY),
        FeatureColumn(name="na__ip", type=CATEGORICAL),
        FeatureColumn(name="na__ip_first", type=CATEGORICAL),
        FeatureColumn(name="count__ip_version", type=P_DISCRETE),
        FeatureColumn(name="na__ip_class_b", type=CATEGORICAL),
        FeatureColumn(name="count__ip_count", type=P_DISCRETE),
        FeatureColumn(name="na__device_ip_geo_city", type=CATEGORICAL),
        FeatureColumn(name="na__device_ip_geo_state", type=CATEGORICAL),
        FeatureColumn(name="na__device_ip_geo_country", type=CATEGORICAL),
        FeatureColumn(name="na__device_ip_geo_zip_code", type=CATEGORICAL),
        FeatureColumn(name="na__device_ip_geo_latitude", type=CATEGORICAL),
        FeatureColumn(name="na__device_ip_geo_longitude", type=CATEGORICAL),
        FeatureColumn(name="na__device_ip_geo_dma_code", type=CATEGORICAL),
        FeatureColumn(name="na__device_ip_geo_area_code", type=CATEGORICAL),
        FeatureColumn(name="na__device_ip_geo_continent", type=CATEGORICAL),
        FeatureColumn(name="na__device_ip_geo_region", type=CATEGORICAL),
        FeatureColumn(name="na__device_ip_geo_time_zone", type=CATEGORICAL),
        FeatureColumn(name="na__device_ip_geo_connection_type", type=CATEGORICAL),
        FeatureColumn(name="na__device_ip_geo_line_speed", type=CATEGORICAL),
        FeatureColumn(name="na__device_ip_geo_routing_type", type=CATEGORICAL),
        FeatureColumn(name="na__device_ip_geo_organization", type=CATEGORICAL),
        FeatureColumn(name="na__device_ip_geo_carrier", type=CATEGORICAL),
        FeatureColumn(name="na__device_ip_geo_anonymizer_status", type=CATEGORICAL),
        FeatureColumn(name="na__device_ip_geo_proxy_type", type=CATEGORICAL),
        FeatureColumn(name="na__device_ip_geo_proxy_level", type=CATEGORICAL),
        FeatureColumn(name="is__device_ip_geo_hosting_facility", type=BINARY),
        FeatureColumn(name="na__device_ip_geo_tld", type=CATEGORICAL),
        FeatureColumn(name="na__device_ip_geo_sld", type=CATEGORICAL),
        FeatureColumn(name="na__device_ip_geo_asn", type=CATEGORICAL),
        FeatureColumn(name="na__device_ip_first", type=CATEGORICAL),
        FeatureColumn(name="count__device_ip_count", type=P_DISCRETE),
        FeatureColumn(name="is__device_ip_mismatch", type=BINARY),
        FeatureColumn(name="is__ip_mismatch", type=BINARY),
        FeatureColumn(name="is__ip_botnet", type=BINARY),
        FeatureColumn(name="na__ip_city", type=CATEGORICAL),
        FeatureColumn(name="na__ip_state", type=CATEGORICAL),
        FeatureColumn(name="na__ip_country", type=CATEGORICAL),
        FeatureColumn(name="na__ip_zip_code", type=CATEGORICAL),
        FeatureColumn(name="na__ip_latitude", type=CATEGORICAL),
        FeatureColumn(name="na__ip_longitude", type=CATEGORICAL),
        FeatureColumn(name="na__ip_continent", type=CATEGORICAL),
        FeatureColumn(name="na__ip_region", type=CATEGORICAL),
        FeatureColumn(name="na__ip_time_zone", type=CATEGORICAL),
        FeatureColumn(name="na__ip_connection_type", type=CATEGORICAL),
        FeatureColumn(name="na__ip_line_speed", type=CATEGORICAL),
        FeatureColumn(name="na__ip_routing_type", type=CATEGORICAL),
        FeatureColumn(name="na__ip_organization", type=CATEGORICAL),
        FeatureColumn(name="na__ip_carrier", type=CATEGORICAL),
        FeatureColumn(name="na__ip_tld", type=CATEGORICAL),
        FeatureColumn(name="na__ip_sld", type=CATEGORICAL),
        FeatureColumn(name="na__ip_asn", type=CATEGORICAL),
        FeatureColumn(name="na__useragent", type=CATEGORICAL),
        FeatureColumn(name="na__useragent_first", type=CATEGORICAL),
        FeatureColumn(name="count__useragent_count", type=P_DISCRETE),
        FeatureColumn(name="is__useragent_mismatch", type=BINARY),
        FeatureColumn(name="na__useragent_browser_name", type=CATEGORICAL),
        FeatureColumn(name="na__useragent_browser_version_full", type=CATEGORICAL),
        FeatureColumn(name="na__useragent_browser_age_days", type=CATEGORICAL),
        FeatureColumn(name="na__useragent_browser_age_years", type=CATEGORICAL),
        FeatureColumn(name="na__useragent_platform_name", type=CATEGORICAL),
        FeatureColumn(name="na__useragent_platform_version_full", type=CATEGORICAL),
        FeatureColumn(name="is__useragent_desktop", type=BINARY),
        FeatureColumn(name="is__useragent_mobile", type=BINARY),
        FeatureColumn(name="is__useragent_other", type=BINARY),
        FeatureColumn(name="na__useragent_first_browser_name", type=CATEGORICAL),
        FeatureColumn(name="na__useragent_first_browser_version_full", type=CATEGORICAL),
        FeatureColumn(name="na__useragent_first_browser_age_days", type=CATEGORICAL),
        FeatureColumn(name="na__useragent_first_browser_age_years", type=CATEGORICAL),
        FeatureColumn(name="na__useragent_first_platform_name", type=CATEGORICAL),
        FeatureColumn(name="na__useragent_first_platform_version_full", type=CATEGORICAL),
        FeatureColumn(name="is__useragent_first_desktop", type=BINARY),
        FeatureColumn(name="is__useragent_first_mobile", type=BINARY),
        FeatureColumn(name="is__useragent_first_other", type=BINARY),
        FeatureColumn(name="na__useragent_platform_version", type=CATEGORICAL),
        FeatureColumn(name="is__input_missing", type=BINARY),
        FeatureColumn(name="is__input_invalid", type=BINARY),
        FeatureColumn(name="na__input_ipr_status", type=CATEGORICAL),
        FeatureColumn(name="count__input_time_on_page", type=P_DISCRETE),
        FeatureColumn(name="is__script_verify_javascript", type=BINARY),
        FeatureColumn(name="na__script_javascript_status", type=CATEGORICAL),
        FeatureColumn(name="is__script_verify_cookie", type=BINARY),
        FeatureColumn(name="na__script_cookie_status", type=CATEGORICAL),
        FeatureColumn(name="is__script_spoofing", type=BINARY),
        FeatureColumn(name="is__script_automation", type=BINARY),
        FeatureColumn(name="is__script_replay", type=BINARY),
        FeatureColumn(name="na__mobile_device_build_manufacturer", type=CATEGORICAL),
        FeatureColumn(name="na__mobile_device_build_model", type=CATEGORICAL),
        FeatureColumn(name="na__mobile_device_build_brand", type=CATEGORICAL),
        FeatureColumn(name="na__mobile_device_language", type=CATEGORICAL),
        FeatureColumn(name="na__mobile_device_time_zone", type=CATEGORICAL),
        FeatureColumn(name="na__mobile_device_sim_operator_name", type=CATEGORICAL),
        FeatureColumn(name="na__mobile_device_battery_status", type=CATEGORICAL),
        FeatureColumn(name="na__mobile_device_country_code", type=CATEGORICAL),
        FeatureColumn(name="na__segment_device_id", type=CATEGORICAL),
    ]
    meta_owner: MetaOwnerInfo = ACCOUNT_ACCESS_AND_UPDATE_TEAM_OWNER_INFO
    tags: list[MetaTag] = [MetaTag(name="domain", value="authentication")]

    def get_compute_windows(self) -> list[ComputeWindow]:
        return [
            StreamWindow(
                offset="0s",
                lookback="2h",
                materialize_cfg=build_deprecate_materialization_cfg(datetime(year=2023, month=2, day=9)),
                expiration_override="365d",
            )
        ]

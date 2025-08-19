from chime_ml.feature_library_v2.common.columns import DEVICE_IP_FIRST_3_OCTETS
from chime_ml.feature_library_v2.common.meta import RISK_DS_TEAM_OWNER_INFO
from chime_ml.feature_store_core.feature_library.abstract.base_family import (
    BaseFeatureFamilyTemplate,
)
from chime_ml.feature_store_core.feature_library.abstract.column import (
    P_CONTINUOUS,
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
    BatchWindow,
    ComputeWindow,
)
from chime_ml.feature_store_core.feature_library.common.columns import (
    LAST_EVENT_TIMESTAMP,
)
from chime_ml.feature_store_core.feature_library.common.materialization_configs import (
    PROD_MATERIALIZATION_CFG,
)


class BaseFamilyTemplate(BaseFeatureFamilyTemplate):
    ff_template_name: str = "device_ip_first_3_octets__entity_rates"
    version: str = "v1"
    description: str = (
        "A feature family to calculate deactivation and dispute rates for device_ip_first_3_octets entity"
    )
    entities: list[Column] = [DEVICE_IP_FIRST_3_OCTETS]

    cte_configs: dict[str, CTEConfig] = {}

    attributes: list[FeatureColumn] = [
        LAST_EVENT_TIMESTAMP,
        FeatureColumn(name="last__nunique_active_users", type=P_DISCRETE),
        FeatureColumn(name="last__nunique_inactive_users", type=P_DISCRETE),
        FeatureColumn(name="last__deactivation_rate", type=P_CONTINUOUS),
    ]

    meta_owner: MetaOwnerInfo = RISK_DS_TEAM_OWNER_INFO
    tags: list[MetaTag] = [MetaTag(name="domain", value="device_ip_first_3_octets")]

    def get_compute_windows(self) -> list[ComputeWindow]:
        batch_windows = [
            BatchWindow(
                offset="0s",
                lookback="7d",
                schedule="0 0 * * *",
                materialize_cfg=PROD_MATERIALIZATION_CFG,
                worker_counts=10,
                expected_freshness=28 * 3600,  # 24 hours + 4 hour buffer (source table gets updated every 24 hours)
            )
        ]
        stream_windows = []

        return batch_windows + stream_windows

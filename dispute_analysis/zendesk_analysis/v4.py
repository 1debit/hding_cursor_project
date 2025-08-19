from chime_ml.feature_library_v2.common.columns import USER_ID
from chime_ml.feature_library_v2.common.meta import RISK_DS_TEAM_OWNER_INFO
from chime_ml.feature_store_core.feature_library.abstract.base_family import (
    BaseFeatureFamilyTemplate,
)
from chime_ml.feature_store_core.feature_library.abstract.column import (
    P_CONTINUOUS,
    P_DISCRETE,
    TIMESTAMP_LTZ,
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
    DEV_MATERIALIZATION_CFG,
)


class BaseFamilyTemplate(BaseFeatureFamilyTemplate):
    ff_template_name: str = "user_id__latest_dispute"
    version: str = "v4"
    description: str = "A feature family to extract the latest dispute features"
    entities: list[Column] = [USER_ID]

    cte_configs: dict[str, CTEConfig] = {}

    attributes: list[FeatureColumn] = [
        LAST_EVENT_TIMESTAMP,
        FeatureColumn(name="last__dispute_timestamp", type=TIMESTAMP_LTZ),
        FeatureColumn(name="last__dispute_amount", type=P_CONTINUOUS),
        FeatureColumn(name="avg__age_of_transaction_in_days", type=P_CONTINUOUS),
        FeatureColumn(name="max__age_of_transaction_in_days", type=P_DISCRETE),
        FeatureColumn(name="min__age_of_transaction_in_days", type=P_DISCRETE),
        FeatureColumn(name="count__txns", type=P_DISCRETE),
        FeatureColumn(name="count__aged_txns", type=P_DISCRETE),
        FeatureColumn(name="count__denied_txns", type=P_DISCRETE),
        FeatureColumn(name="ratio__no_denied_txns_no_total_txns", type=P_CONTINUOUS),
    ]

    meta_owner: MetaOwnerInfo = RISK_DS_TEAM_OWNER_INFO
    tags: list[MetaTag] = [MetaTag(name="domain", value="latest_dispute")]

    def get_compute_windows(self) -> list[ComputeWindow]:
        batch_windows = [
            BatchWindow(
                offset="0s",
                lookback="hist",
                schedule="30 */2 * * *",
                materialize_cfg=DEV_MATERIALIZATION_CFG,
                worker_counts=30,
                expected_freshness=3 * 60 * 60,  # 2 hours offset + 1 hour buffer
            )
        ]
        stream_windows = []

        return batch_windows + stream_windows

from chime_ml.feature_library_v2.common.columns import USER_ID
from chime_ml.feature_library_v2.common.meta import RISK_INSIGHTS_TEAM_OWNER_INFO
from chime_ml.feature_store_core.feature_library.abstract.base_family import (
    BaseFeatureFamilyTemplate,
)
from chime_ml.feature_store_core.feature_library.abstract.column import (
    CONTINUOUS,
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
    ff_template_name: str = "user_id__dispute_to_spend"
    version: str = "v1"
    description: str = "Feature Family to capture the dispute to total spend ratios"
    entities: list[Column] = [USER_ID]

    cte_configs: dict[str, CTEConfig] = {}

    attributes: list[FeatureColumn] = [
        LAST_EVENT_TIMESTAMP,
        FeatureColumn(name="sum__total_spend", type=CONTINUOUS),
        FeatureColumn(name="sum__disputed_amount", type=CONTINUOUS),
        FeatureColumn(name="count__disputed_transactions", type=P_DISCRETE),
        FeatureColumn(name="ratio__dispute_spend_amount", type=CONTINUOUS),
    ]

    meta_owner: MetaOwnerInfo = RISK_INSIGHTS_TEAM_OWNER_INFO
    tags: list[MetaTag] = [MetaTag(name="domain", value="User dispute to spend ratios")]

    def get_compute_windows(self) -> list[ComputeWindow]:
        batch_windows = [
            BatchWindow(
                offset="2h",  # although offset=2hour but the source table update actually have at least 1 day delay
                lookback="30d",
                schedule="0 5 * * *",
                materialize_cfg=PROD_MATERIALIZATION_CFG,
                worker_counts=10,
                non_standard_window_justification="Non-standard window was created before standard window enforcement. Granting exemption to keep the systems running; Future non-standard windows/versions must have a business justification in order to be approved.",
            ),
            BatchWindow(
                offset="2h",
                lookback="365d",
                schedule="0 5 * * *",
                materialize_cfg=PROD_MATERIALIZATION_CFG,
                worker_counts=10,
                non_standard_window_justification="Non-standard window was created before standard window enforcement. Granting exemption to keep the systems running; Future non-standard windows/versions must have a business justification in order to be approved.",
            ),
        ]
        stream_windows = []

        return batch_windows + stream_windows

from chime_ml.feature_library_v2.common.columns import MERCHANT_NAME
from chime_ml.feature_library_v2.common.meta import RISK_INSIGHTS_TEAM_OWNER_INFO
from chime_ml.feature_store_core.feature_library.abstract.base_family import (
    BaseFeatureFamilyTemplate,
)
from chime_ml.feature_store_core.feature_library.abstract.column import (
    CONTINUOUS,
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
    ff_template_name: str = "merchant_name__dispute_rate_3ds"
    version: str = "v1"
    description: str = "3ds merchant level dispute rate summary"
    entities: list[Column] = [MERCHANT_NAME]

    cte_configs: dict[str, CTEConfig] = {}

    attributes: list[FeatureColumn] = [
        LAST_EVENT_TIMESTAMP,
        FeatureColumn(name="count__auth_user", type=P_DISCRETE),
        FeatureColumn(name="count__auth", type=P_DISCRETE),
        FeatureColumn(name="sum__auth", type=CONTINUOUS),
        FeatureColumn(name="count__disputed_user", type=P_DISCRETE),
        FeatureColumn(name="count__disputed_unauth_user", type=P_DISCRETE),
        FeatureColumn(name="count__dispute", type=P_DISCRETE),
        FeatureColumn(name="count__dispute_unauth", type=P_DISCRETE),
        FeatureColumn(name="sum__dispute", type=CONTINUOUS),
        FeatureColumn(name="sum__dispute_unauth", type=CONTINUOUS),
        FeatureColumn(
            name="ratio__disputed_user",
            type=P_CONTINUOUS,
        ),
        FeatureColumn(
            name="ratio__disputed_unauth_user",
            type=P_CONTINUOUS,
        ),
        FeatureColumn(
            name="ratio__dispute_cnt",
            type=P_CONTINUOUS,
        ),
        FeatureColumn(
            name="ratio__dispute_unauth_cnt",
            type=P_CONTINUOUS,
        ),
        FeatureColumn(
            name="ratio__dispute_sum_bps",
            type=P_CONTINUOUS,
        ),
        FeatureColumn(
            name="ratio__dispute_unauth_sum_bps",
            type=P_CONTINUOUS,
        ),
        FeatureColumn(
            name="ratio__dispute_sum",
            type=P_CONTINUOUS,
        ),
    ]

    meta_owner: MetaOwnerInfo = RISK_INSIGHTS_TEAM_OWNER_INFO
    tags: list[MetaTag] = [MetaTag(name="domain", value="provisioning_hist")]

    def get_compute_windows(self) -> list[ComputeWindow]:
        batch_windows = [
            BatchWindow(
                offset="0s",
                lookback="180d",
                schedule="0 1 * * *",
                materialize_cfg=PROD_MATERIALIZATION_CFG,
                worker_counts=100,
            ),
            BatchWindow(
                offset="0s",
                lookback="7d",
                schedule="0 1 * * *",
                materialize_cfg=PROD_MATERIALIZATION_CFG,
                worker_counts=100,
            ),
            BatchWindow(
                offset="0s",
                lookback="14d",
                schedule="0 1 * * *",
                materialize_cfg=PROD_MATERIALIZATION_CFG,
                worker_counts=100,
                non_standard_window_justification="Calculate 14 day merchant dispute rate for more dynamic fraud tracking",
            ),
            BatchWindow(
                offset="0s",
                lookback="30d",
                schedule="0 1 * * *",
                materialize_cfg=PROD_MATERIALIZATION_CFG,
                worker_counts=100,
            ),
        ]

        stream_windows = []

        return batch_windows + stream_windows

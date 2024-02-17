import '../generated/app.pbgrpc.dart';

import 'dart:core' as $core;
import 'package:grpc/grpc.dart';

const bearerToken = "eyJhbGciOiJFQ0RILUVTK0EyNTZLVyIsImN0eSI6IkpXVCIsImVuYyI6IkEyNTZHQ00iLCJlcGsiOnsia3R5IjoiRUMiLCJjcnYiOiJQLTI1NiIsIngiOiJWREhaenNTVG42M28xY1dDeWx4LWx3bTRSUmhjZ0FqdTZDa2dQdTZhUHJFIiwieSI6IkVBOTBJVTVWdUZTM1pkSHhKMEFMbnQ1bUJ5VzQ4TXQ4WEZ0R18tSktWb1UifSwidHlwIjoiSldUIiwiemlwIjoiREVGIn0.KxH03uqwrn3FpgWUeyI_TKuPtKK0xI8NOZ1yiY_iE_voYGTTm08m7g.jwIg5hijcaxXpONy.JsRorrRhPo1dIqLg1y0vmFViXKErbyZlCIQ_3XLzDpP5Ea4qg8pTQBhOUiTZ42ts1_Xig8m_J55TrxOIyG9dVKodz9E7_tYt_1ZNkzuAEEYX9CzyQFevU9eHthmCv19czJnKZmqHCRBUBIUk3BO8-9v0SByhqn_LOzRtMdSsy-bbTP7jjwzSlK2PxaMSOxGpPG-A8ZDU2VFN.v0wilNbaLW73G5Dz-d-Ayw";

final apiClient = AppServiceClient(
  ClientChannel(
    'ldt.renbou.ru',
    port: 30081,
    options: const ChannelOptions(
      credentials: ChannelCredentials.insecure(),
    ),
  ),
  // options: CallOptions(
  //   metadata: {
  //     'Authorization': 'Bearer $bearerToken'
  //   },
  // ),
);

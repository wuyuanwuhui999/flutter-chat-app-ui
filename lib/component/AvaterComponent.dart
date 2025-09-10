import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/UserInfoProvider.dart';
import '../router/index.dart';
import '../theme/ThemeColors.dart';
import '../utils/common.dart';

/*-----------------------头像组件------------------------*/
class AvaterComponent extends StatelessWidget {
  final String? avater;
  final double size;

  const AvaterComponent({super.key,  required this.size, this.avater});

  @override
  Widget build(BuildContext context) {
    String avater = Provider.of<UserInfoProvider>(context).userInfo.avater;
    return GestureDetector(child: ClipOval(
        child: avater != "" && avater != null ? Image.network(
          //从全局的provider中获取用户信息
          getMusicCover(avater),
          height: size,
          width: size,
          fit: BoxFit.cover,
        ) : Image.asset(
          //从全局的provider中获取用户信息
          "lib/assets/images/default_avater.png",
          height: size,
          width: size,
          fit: BoxFit.cover,
        )

    ),onTap: (){
      Routes.router.navigateTo(context, '/UserPage',replace: false);
    });
  }
}
/*-----------------------头像组件------------------------*/

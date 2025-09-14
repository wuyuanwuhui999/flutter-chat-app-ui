const servicePath = {
  'login': '/service/user/login', //登录
  'getUserData': '/service/user-getway/getUserData', // 获取用户信息
  'updateUser': '/service/user-getway/updateUser',//更新用户信息
  'register': '/service/user/register',//注册
  'vertifyUser': '/service/user/vertifyUser',// 校验账号是否存在
  'sendEmailVertifyCode': '/service/user/sendEmailVertifyCode',// 找回密码
  'resetPassword': '/service/user/resetPassword',// 重置密码
  'updateAvater':'/service/user-getway/updateAvater',//更新头像
  'updatePassword': '/service/user-getway/updatePassword',//更新密码
  'loginByEmail': '/service/user/loginByEmail',//邮箱登录
  'chat':"/service/ai/chat",// ai聊天
  'getChatHistory': "/service/ai/getChatHistory",// ai聊天
  'chatWs': "/service/ai/ws/chat",// ai聊天
  'getModelList': "/service/ai/getModelList",// ai聊天
  'getDocList': "/service/ai/getDocList",// 查询我的文档
  'deleteDoc': "/service/ai/deleteDoc/",// 查询我的文档
  'getDirectoryList':"/service/ai/getDirectoryList",// 按照租户查询文档目录列表
  'createDir': "/service/ai/createDir",// 创建目录
  'getTenantUser':"/service/tenant/getTenantUser",// 获取当前租户信息
  'getUserTenantList': "/service/tenant/getUserTenantList",// 获取用户的所有租户
  'getTenantUserList': "/service/tenant/getTenantUserList",// 获取当前租户下的所有租户
  'addAdmin': "/service/tenant/addAdmin",// 给用户添加管理员
  'cancelAdmin': "/service/tenant/cancelAdmin",// 删除管理员
  'searchUsers': "/service/user-getway/searchUsers",// 搜索用户
  'addTenantUser': "/service/tenant/addTenantUser",// 添加租户用户
  'deleteTenantUser': "/service/tenant/deleteTenantUser",// 删除租户用户
};

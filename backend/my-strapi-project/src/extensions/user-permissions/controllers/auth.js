const { sanitizeEntity } = require('@strapi/utils');

module.exports = {
  async register(ctx) {
    const { email, username, password, phone, type } = ctx.request.body;

    if (!email || !username || !password) {
      return ctx.badRequest('Missing required fields');
    }

    const newUser = await strapi.plugins['users-permissions'].services.user.add({
      email,
      username,
      password,
      phone,
      type,
      confirmed: true,
    });

    ctx.send(sanitizeEntity(newUser, { model: strapi.plugins['users-permissions'].models.user }));
  },
};

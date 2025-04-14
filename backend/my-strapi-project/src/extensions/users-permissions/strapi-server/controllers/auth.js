'use strict';

const { getService } = require('@strapi/plugin-users-permissions/server/utils');
const { ApplicationError, ValidationError } = require('@strapi/utils').errors;

module.exports = {
    async register(ctx) {
        const pluginStore = strapi.store({ type: 'plugin', name: 'users-permissions' });

        const settings = await pluginStore.get({ key: 'advanced' });
        const { email, username, password, phone, type } = ctx.request.body;

        // Check for required fields
        if (!email) throw new ValidationError('Email is required');
        if (!password) throw new ValidationError('Password is required');
        if (!username) throw new ValidationError('Username is required');

        // Check if user exists
        const userExists = await strapi.query('plugin::users-permissions.user').findOne({
            where: { email },
        });

        if (userExists) {
            throw new ApplicationError('Email is already taken');
        }

        const newUser = await strapi.query('plugin::users-permissions.user').create({
            data: {
                email,
                username,
                password,
                provider: 'local',
                phone, // custom field
                type,  // custom field
                confirmed: !settings.email_confirmation,
                blocked: false,
            },
        });

        // Return sanitized user (no password)
        const sanitizedUser = await getService('user').sanitizeOutput(newUser, ctx);

        ctx.body = {
            user: sanitizedUser,
        };
    },
};

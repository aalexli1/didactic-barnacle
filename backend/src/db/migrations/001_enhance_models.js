module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn('users', 'level', {
      type: Sequelize.INTEGER,
      defaultValue: 1,
      allowNull: false
    });

    await queryInterface.addColumn('users', 'experience', {
      type: Sequelize.INTEGER,
      defaultValue: 0,
      allowNull: false
    });

    await queryInterface.addColumn('users', 'settings', {
      type: Sequelize.JSONB,
      defaultValue: {
        notificationsEnabled: true,
        locationSharingEnabled: true,
        privateProfile: false,
        discoveryRadius: 1000
      },
      allowNull: false
    });

    await queryInterface.addColumn('treasures', 'altitude', {
      type: Sequelize.FLOAT,
      defaultValue: 0,
      allowNull: false
    });

    await queryInterface.addColumn('treasures', 'type', {
      type: Sequelize.ENUM('standard', 'premium', 'special', 'event'),
      defaultValue: 'standard',
      allowNull: false
    });

    await queryInterface.addColumn('treasures', 'media_url', {
      type: Sequelize.STRING,
      allowNull: true
    });

    await queryInterface.addColumn('discoveries', 'photo_url', {
      type: Sequelize.STRING,
      allowNull: true
    });

    await queryInterface.addColumn('discoveries', 'comment', {
      type: Sequelize.TEXT,
      allowNull: true
    });

    await queryInterface.addColumn('discoveries', 'reaction_type', {
      type: Sequelize.ENUM('like', 'love', 'wow', 'funny', 'cool'),
      allowNull: true
    });

    await queryInterface.createTable('sync_metadata', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true
      },
      entity_type: {
        type: Sequelize.STRING,
        allowNull: false
      },
      entity_id: {
        type: Sequelize.UUID,
        allowNull: false
      },
      last_modified: {
        type: Sequelize.DATE,
        allowNull: false
      },
      version: {
        type: Sequelize.INTEGER,
        defaultValue: 1,
        allowNull: false
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false
      }
    });

    await queryInterface.addIndex('sync_metadata', ['entity_type', 'entity_id'], {
      unique: true,
      name: 'idx_sync_metadata_entity'
    });

    await queryInterface.addIndex('sync_metadata', ['last_modified'], {
      name: 'idx_sync_metadata_modified'
    });

    await queryInterface.addIndex('treasures', ['type', 'is_active'], {
      name: 'idx_treasures_type_active'
    });

    await queryInterface.addIndex('treasures', ['creator_id', 'created_at'], {
      name: 'idx_treasures_creator_date'
    });

    await queryInterface.addIndex('discoveries', ['user_id', 'discovered_at'], {
      name: 'idx_discoveries_user_date'
    });

    await queryInterface.sequelize.query('SELECT create_spatial_indexes();');
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.removeColumn('users', 'level');
    await queryInterface.removeColumn('users', 'experience');
    await queryInterface.removeColumn('users', 'settings');
    await queryInterface.removeColumn('treasures', 'altitude');
    await queryInterface.removeColumn('treasures', 'type');
    await queryInterface.removeColumn('treasures', 'media_url');
    await queryInterface.removeColumn('discoveries', 'photo_url');
    await queryInterface.removeColumn('discoveries', 'comment');
    await queryInterface.removeColumn('discoveries', 'reaction_type');
    await queryInterface.dropTable('sync_metadata');
    await queryInterface.removeIndex('treasures', 'idx_treasures_type_active');
    await queryInterface.removeIndex('treasures', 'idx_treasures_creator_date');
    await queryInterface.removeIndex('discoveries', 'idx_discoveries_user_date');
  }
};
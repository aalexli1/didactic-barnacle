module.exports = (sequelize, DataTypes) => {
  const SyncMetadata = sequelize.define('SyncMetadata', {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    entity_type: {
      type: DataTypes.STRING,
      allowNull: false
    },
    entity_id: {
      type: DataTypes.UUID,
      allowNull: false
    },
    last_modified: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW
    },
    version: {
      type: DataTypes.INTEGER,
      defaultValue: 1,
      allowNull: false
    }
  }, {
    tableName: 'sync_metadata',
    timestamps: true,
    underscored: true,
    indexes: [
      {
        unique: true,
        fields: ['entity_type', 'entity_id'],
        name: 'idx_sync_metadata_entity'
      },
      {
        fields: ['last_modified'],
        name: 'idx_sync_metadata_modified'
      }
    ]
  });

  SyncMetadata.updateVersion = async function(entityType, entityId) {
    const [metadata, created] = await this.findOrCreate({
      where: {
        entity_type: entityType,
        entity_id: entityId
      },
      defaults: {
        last_modified: new Date(),
        version: 1
      }
    });

    if (!created) {
      await metadata.increment('version');
      metadata.last_modified = new Date();
      await metadata.save();
    }

    return metadata;
  };

  SyncMetadata.getChangesSince = async function(since) {
    return await this.findAll({
      where: {
        last_modified: {
          [sequelize.Op.gt]: since
        }
      },
      order: [['last_modified', 'ASC']]
    });
  };

  return SyncMetadata;
};
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

module.exports = {
  up: async (queryInterface, Sequelize) => {
    const hashedPassword = await bcrypt.hash('password123', 10);
    const now = new Date();
    
    const users = [
      {
        id: uuidv4(),
        username: 'demo_user',
        email: 'demo@example.com',
        password: hashedPassword,
        avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=demo',
        bio: 'AR treasure hunter enthusiast',
        level: 5,
        experience: 2500,
        treasures_created: 10,
        treasures_found: 25,
        points: 5000,
        settings: JSON.stringify({
          notificationsEnabled: true,
          locationSharingEnabled: true,
          privateProfile: false,
          discoveryRadius: 2000
        }),
        created_at: now,
        updated_at: now
      },
      {
        id: uuidv4(),
        username: 'test_user',
        email: 'test@example.com',
        password: hashedPassword,
        avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=test',
        bio: 'Just started treasure hunting!',
        level: 1,
        experience: 0,
        treasures_created: 0,
        treasures_found: 0,
        points: 0,
        settings: JSON.stringify({
          notificationsEnabled: true,
          locationSharingEnabled: true,
          privateProfile: false,
          discoveryRadius: 1000
        }),
        created_at: now,
        updated_at: now
      }
    ];

    await queryInterface.bulkInsert('users', users);

    const treasureLocations = [
      { lat: 37.7749, lon: -122.4194, title: 'Golden Gate Treasure', hint: 'Near the famous bridge' },
      { lat: 37.7955, lon: -122.3937, title: 'Coit Tower Mystery', hint: 'Look up at the tower' },
      { lat: 37.8024, lon: -122.4058, title: 'Fisherman\'s Wharf Secret', hint: 'Where the sea lions play' },
      { lat: 37.7694, lon: -122.4862, title: 'Golden Gate Park Gem', hint: 'Among the gardens' },
      { lat: 37.7599, lon: -122.4148, title: 'Mission District Prize', hint: 'Where murals tell stories' },
      { lat: 37.7883, lon: -122.4076, title: 'Union Square Surprise', hint: 'Shopping and more' },
      { lat: 37.8087, lon: -122.4098, title: 'North Beach Hidden', hint: 'Little Italy awaits' },
      { lat: 37.7614, lon: -122.4356, title: 'Castro Treasure', hint: 'Rainbow crosswalks nearby' },
      { lat: 37.7847, lon: -122.4065, title: 'Chinatown Mystery', hint: 'Dragon gates guard it' },
      { lat: 37.8270, lon: -122.4230, title: 'Alcatraz View Point', hint: 'The rock in sight' }
    ];

    const treasures = treasureLocations.map((loc, index) => ({
      id: uuidv4(),
      creator_id: users[index % 2].id,
      title: loc.title,
      description: `An exciting treasure hunt at ${loc.title}`,
      message: `Congratulations! You found the ${loc.title}!`,
      location: Sequelize.fn('ST_SetSRID', Sequelize.fn('ST_MakePoint', loc.lon, loc.lat), 4326),
      latitude: loc.lat,
      longitude: loc.lon,
      altitude: Math.random() * 100,
      type: ['standard', 'premium', 'special'][index % 3],
      ar_object: JSON.stringify({
        type: ['chest', 'gem', 'coin'][index % 3],
        modelUrl: null,
        color: ['#FFD700', '#C0C0C0', '#CD7F32'][index % 3],
        scale: 1.0 + (Math.random() * 0.5)
      }),
      visibility: 'public',
      difficulty: ['easy', 'medium', 'hard'][index % 3],
      hint: loc.hint,
      points: (index + 1) * 10,
      max_discoveries: index < 5 ? null : 10 + index,
      is_active: true,
      expires_at: index < 7 ? null : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      created_at: new Date(Date.now() - (10 - index) * 24 * 60 * 60 * 1000),
      updated_at: now
    }));

    await queryInterface.bulkInsert('treasures', treasures);

    const discoveries = [];
    for (let i = 0; i < 5; i++) {
      discoveries.push({
        id: uuidv4(),
        treasure_id: treasures[i].id,
        user_id: users[1].id,
        discovered_at: new Date(Date.now() - i * 24 * 60 * 60 * 1000),
        points_earned: treasures[i].points,
        time_to_find: Math.floor(Math.random() * 3600),
        distance_from_treasure: Math.random() * 10,
        comment: ['Amazing find!', 'So cool!', 'Love it!', 'Great treasure!', 'Fun hunt!'][i],
        reaction_type: ['like', 'love', 'wow', 'cool', 'funny'][i],
        created_at: now,
        updated_at: now
      });
    }

    await queryInterface.bulkInsert('discoveries', discoveries);

    const syncMetadata = [];
    users.forEach(user => {
      syncMetadata.push({
        id: uuidv4(),
        entity_type: 'user',
        entity_id: user.id,
        last_modified: now,
        version: 1,
        created_at: now,
        updated_at: now
      });
    });
    
    treasures.forEach(treasure => {
      syncMetadata.push({
        id: uuidv4(),
        entity_type: 'treasure',
        entity_id: treasure.id,
        last_modified: now,
        version: 1,
        created_at: now,
        updated_at: now
      });
    });

    await queryInterface.bulkInsert('sync_metadata', syncMetadata);
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.bulkDelete('sync_metadata', null, {});
    await queryInterface.bulkDelete('discoveries', null, {});
    await queryInterface.bulkDelete('treasures', null, {});
    await queryInterface.bulkDelete('users', null, {});
  }
};
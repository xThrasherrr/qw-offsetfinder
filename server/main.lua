lib.addCommand('offsets', {
    help = 'Find offets for a shell',
    params = {},
    restricted = 'group.admin'
}, function(source, args, raw)
    TriggerClientEvent('qw-offset:client:offsetFinder', source)
end)
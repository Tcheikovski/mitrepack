settings.define('mitrepack.version')

if not fs.isDir(rdir) then
    print('Initializing Mitrepack files...')
    fs.makeDir(rdir)
end


import RadioPlayer

enum SidebarDestination: Hashable {
    case collection(ArchiveCollection)
    case favorites
    case library
}

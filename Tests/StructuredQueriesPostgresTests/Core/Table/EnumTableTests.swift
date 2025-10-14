#if StructuredQueriesPostgresCasePaths
    import CasePaths
    import Dependencies
    import Foundation
    import InlineSnapshotTesting
    import StructuredQueriesPostgres
    import StructuredQueriesPostgresTestSupport
    import Testing

    extension SnapshotTests {
        @Suite struct EnumTableTests {

            @Test func selectAll() async {
                await assertSQL(
                    of: Attachment.all
                ) {
                    """
                    SELECT "attachments"."id", "attachments"."link", "attachments"."note", "attachments"."videoURL", "attachments"."videoKind", "attachments"."imageCaption", "attachments"."imageURL"
                    FROM "attachments"
                    """
                }
            }

            @Test func customSelect() async {
                await assertSQL(
                    of: Attachment.select { $0.kind }
                ) {
                    """
                    SELECT "attachments"."link", "attachments"."note", "attachments"."videoURL", "attachments"."videoKind", "attachments"."imageCaption", "attachments"."imageURL"
                    FROM "attachments"
                    """
                }
            }

            @Test func dynamicMemberLookup_CasePath() async {
                await assertSQL(
                    of: Attachment.select(\.kind.image)
                ) {
                    """
                    SELECT "attachments"."imageCaption", "attachments"."imageURL"
                    FROM "attachments"
                    """
                }
            }

            @Test func dynamicMemberLookup_MultipleLevels() async {
                await assertSQL(
                    of: Attachment.select(\.kind.image.caption)
                ) {
                    """
                    SELECT "attachments"."imageCaption"
                    FROM "attachments"
                    """
                }
            }

            @Test func whereClause() async {
                await assertSQL(
                    of: Attachment.where {
                        $0.kind.is(Attachment.Kind.note("Today was a good day"))
                    }
                ) {
                    """
                    SELECT "attachments"."id", "attachments"."link", "attachments"."note", "attachments"."videoURL", "attachments"."videoKind", "attachments"."imageCaption", "attachments"."imageURL"
                    FROM "attachments"
                    WHERE ("attachments"."link", "attachments"."note", "attachments"."videoURL", "attachments"."videoKind", "attachments"."imageCaption", "attachments"."imageURL") IS NOT DISTINCT FROM (NULL, 'Today was a good day', NULL, NULL, NULL, NULL)
                    """
                }
                await assertSQL(
                    of: Attachment.where { $0.kind.note.is("Today was a good day") }
                ) {
                    """
                    SELECT "attachments"."id", "attachments"."link", "attachments"."note", "attachments"."videoURL", "attachments"."videoKind", "attachments"."imageCaption", "attachments"."imageURL"
                    FROM "attachments"
                    WHERE ("attachments"."note") IS NOT DISTINCT FROM ('Today was a good day')
                    """
                }
            }

            @Test func whereClause_DynamicMemberLookup() async {
                await assertSQL(
                    of: Attachment.where { $0.kind.image.isNot(nil) }
                ) {
                    """
                    SELECT "attachments"."id", "attachments"."link", "attachments"."note", "attachments"."videoURL", "attachments"."videoKind", "attachments"."imageCaption", "attachments"."imageURL"
                    FROM "attachments"
                    WHERE ("attachments"."imageCaption", "attachments"."imageURL") IS DISTINCT FROM (NULL, NULL)
                    """
                }
            }

            @Test func whereClauseEscapeHatch() async {
                await assertSQL(
                    of:
                        Attachment
                        .where {
                            #sql("(\($0.kind.image)) IS DISTINCT FROM (NULL, NULL)")
                        }
                ) {
                    """
                    SELECT "attachments"."id", "attachments"."link", "attachments"."note", "attachments"."videoURL", "attachments"."videoKind", "attachments"."imageCaption", "attachments"."imageURL"
                    FROM "attachments"
                    WHERE ("attachments"."imageCaption", "attachments"."imageURL") IS DISTINCT FROM (NULL, NULL)
                    """
                }
            }

            @Test func insert() async {
                await assertSQL(
                    of: Attachment.insert {
                        Attachment.Draft(kind: .note("Hello world!"))
                        Attachment.Draft(
                            kind: .image(
                                Attachment.Image(
                                    caption: "Image",
                                    url: URL(string: "image.jpg")!
                                )
                            )
                        )
                    }
                    .returning(\.self)
                ) {
                    """
                    INSERT INTO "attachments"
                    ("id", "link", "note", "videoURL", "videoKind", "imageCaption", "imageURL")
                    VALUES
                    (DEFAULT, NULL, 'Hello world!', NULL, NULL, NULL, NULL), (DEFAULT, NULL, NULL, NULL, NULL, 'Image', 'image.jpg')
                    RETURNING "id", "link", "note", "videoURL", "videoKind", "imageCaption", "imageURL"
                    """
                }
            }

            @Test func update() async {
                await assertSQL(
                    of:
                        Attachment
                        .find(1)
                        .update {
                            $0.kind = .note("Good bye world!")
                        }
                        .returning(\.self)
                ) {
                    """
                    UPDATE "attachments"
                    SET "link" = NULL, "note" = 'Good bye world!', "videoURL" = NULL, "videoKind" = NULL, "imageCaption" = NULL, "imageURL" = NULL
                    WHERE ("attachments"."id") IN (1)
                    RETURNING "id", "link", "note", "videoURL", "videoKind", "imageCaption", "imageURL"
                    """
                }
            }
        }
    }

    @Table private struct Attachment {
        let id: Int
        let kind: Kind

        @CasePathable @Selection
        fileprivate enum Kind {
            case link(URL)
            case note(String)
            case video(Attachment.Video)
            case image(Attachment.Image)
        }

        @Selection fileprivate struct Video {
            @Column("videoURL")
            let url: URL
            @Column("videoKind")
            var kind: Kind
            fileprivate enum Kind: String, QueryBindable { case youtube, vimeo }
        }
        @Selection fileprivate struct Image {
            @Column("imageCaption")
            let caption: String
            @Column("imageURL")
            let url: URL
        }
    }
#endif

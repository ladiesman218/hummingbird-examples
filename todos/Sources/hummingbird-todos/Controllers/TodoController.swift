import Foundation
import Hummingbird
import HummingbirdFluent
import FluentKit
import NIO

struct TodoController {
    func addRoutes(to group: HBRouterGroup) {
        group
            .get(use: list)
            .post(use: create)
            .delete(use: deleteAll)
            .patch(use: update)
            .put(":id", use: update)
    }
    
    func list(_ request: HBRequest) -> EventLoopFuture<[Todo]> {
        return Todo.query(on: request.db).all()
    }

    func create(_ request: HBRequest) -> EventLoopFuture<Todo> {
        guard let todo = try? request.decode(as: Todo.self) else { return request.failure(HBHTTPError(.badRequest)) }
        return todo.save(on: request.db).map { request.response.status = .created; return todo }
    }

    func get(_ request: HBRequest) -> EventLoopFuture<Todo?> {
        guard let id = request.parameters.get("id", as: UUID.self) else { return request.failure(HBHTTPError(.badRequest)) }
        return Todo.find(id, on: request.db)
    }

    func update(_ request: HBRequest) -> EventLoopFuture<Todo> {
        guard let newTodo = try? request.decode(as: Todo.self) else { return request.failure(HBHTTPError(.badRequest)) }
        return Todo.query(on: request.db)
            .filter(\.$title == "Test")
            .first()
            .unwrap(orError: HBHTTPError(.notFound))
            .flatMap { todo -> EventLoopFuture<Todo> in
                todo.order = newTodo.order
                return todo.update(on: request.db).map { todo }
            }
    }

    func deleteAll(_ request: HBRequest) -> EventLoopFuture<HTTPResponseStatus> {
        return Todo.query(on: request.db)
            .delete()
            .transform(to: .ok)
    }
}

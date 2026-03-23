# TRANSCRIPT — Truerul — first session v0

Status: DRAFT
Language: RU

```text
TRUERUL :: RU :: цикл 00 :: формы пока ведут себя прилично
> (entity эвридика-9 :kind автономный-андроид)
[ok] entity registered: эвридика-9 :: kind автономный-андроид

> (entity астрей :kind бог)
[ok] entity registered: астрей :: kind бог

> (relation эвридика-9 ищет астрей)
[ok] relation registered: эвридика-9 --ищет--> астрей

> (state эвридика-9 сомнение)
[ok] state registered: эвридика-9 :: сомнение

> (query (relation? эвридика-9 ищет X))
[query]
X = астрей

> (quote (state эвридика-9 сомнение))
[form]
(state эвридика-9 сомнение)

> (log)
[log]
01. entity эвридика-9 :kind автономный-андроид
02. entity астрей :kind бог
03. relation эвридика-9 ищет астрей
04. state эвридика-9 сомнение
05. query (relation? эвридика-9 ищет X)
06. quote (state эвридика-9 сомнение)

> (help)
[help]
(entity <id> :kind <kind>)
(relation <subject> <predicate> <object>)
(state <target> <state>)
(rule <id>? :if <condition> :then <consequence>)
(query <pattern>)
(quote <form>)
(eval <form>)
(view <name>?)
(log)
(step)
(clear)

> (surface :lang en)
[ok] surface switched: EN

TRUERUL :: EN :: cycle 00 :: several forms already suspect they are concepts
> (query (entity? X :kind god))
[query]
X = astraeus
```

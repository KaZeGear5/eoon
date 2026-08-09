import 'package:flutter/material.dart';
import 'package:flutter_carplay/flutter_carplay.dart';

void initCarPlay() {
  FlutterCarplay.setRootTemplate(
    rootTemplate: CPTemplate(
      systemIcon: "car.fill",
      title: "EooN Navigation",
      // Template de carte/navigation pour CarPlay
      views: [
        CPListTemplate(
          title: "EooN",
          sections: [
            CPListSection(
              header: "Navigation Rapide",
              items: [
                CPListItem(
                  text: "Démarrer Guidage",
                  detailText: "Rechercher un itinéraire",
                  onPress: (complete, self) {
                    print("Bouton CarPlay cliqué");
                    complete();
                  },
                ),
                CPListItem(
                  text: "Signaler un Danger",
                  detailText: "Police, Accident, Bouchon",
                  onPress: (complete, self) {
                    // Action de signalement
                    complete();
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}
